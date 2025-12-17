import UIKit
import os

import PersistenceInterface
import SharedFoundation

struct ImageLoaderCore: Sendable {
    private let engine: ImageEngine
    private let pipeline: ImageLoadPipeline

    private let prefetchTasks = OSAllocatedUnfairLock(initialState: [URL: (id: UUID, task: Task<Void, Never>)]())
    private let revalidating = OSAllocatedUnfairLock(initialState: Set<URL>())

    init(engine: ImageEngine, diskClient: FileClient, diskConfiguration: ImageDiskCacheConfiguration) {
        self.engine = engine

        let decodeGate = ConcurrencyGate.forCPUBoundWork()
        let decode = engine.decode
        let gatedDecode: @Sendable (Data, CGSize?) async -> UIImage? = { data, pixelSize in
            (try? await decodeGate.withPermit { await decode(data, pixelSize) }) ?? nil
        }

        self.pipeline = ImageLoadPipeline(
            stages: [
                .memoryCache(MemoryCache()),
                .deduplication(),
                .diskCache(
                    DiskCache(client: diskClient, configuration: diskConfiguration),
                    decode: gatedDecode
                ),
            ],
            terminal: ImageLoadPipeline.fetchTerminal(engine: engine, decode: gatedDecode)
        )
    }

    func load(
        _ url: URL,
        policy: ImageCachePolicy = .standard,
        targetPixelSize: CGSize? = nil
    ) async throws -> UIImage {
        try await run(url, policy: policy, intent: .display, targetPixelSize: targetPixelSize)
    }

    private func run(
        _ url: URL,
        policy: ImageCachePolicy,
        intent: ImageLoadContext.Intent,
        targetPixelSize: CGSize?
    ) async throws -> UIImage {
        let context = ImageLoadContext(
            url: url,
            behavior: policy.cacheBehavior,
            intent: intent,
            etag: nil,
            targetPixelSize: targetPixelSize
        )
        let outcome = try await pipeline.load(context)
        if let stale = outcome.staleETag {
            revalidate(
                url,
                etag: stale.etag,
                generation: stale.generation,
                targetPixelSize: targetPixelSize
            )
        }
        return outcome.image
    }

    private func revalidate(_ url: URL, etag: String?, generation: Int, targetPixelSize: CGSize?) {
        let inserted = self.revalidating.withLockUnchecked { $0.insert(url).inserted }
        guard inserted else { return }

        Task { [pipeline, revalidating] in
            defer { revalidating.withLockUnchecked { _ = $0.remove(url) } }
            _ = try? await pipeline.load(
                ImageLoadContext(
                    url: url,
                    behavior: .standard,
                    intent: .revalidate,
                    etag: etag,
                    revalidatingGeneration: generation,
                    targetPixelSize: targetPixelSize
                )
            )
        }
    }

    func prefetch(_ urls: [URL], targetPixelSize: CGSize?) {
        if let enginePrefetch = engine.prefetch {
            enginePrefetch(urls)
            return
        }
        self.prefetchTasks.withLockUnchecked { tasks in
            for url in urls where tasks[url] == nil {
                let id = UUID()
                tasks[url] = (id, Task {
                    guard !Task.isCancelled else { return }
                    _ = try? await self.run(
                        url,
                        policy: .standard,
                        intent: .prefetch,
                        targetPixelSize: targetPixelSize
                    )
                    self.prefetchTasks.withLockUnchecked { current in
                        if current[url]?.id == id {
                            current[url] = nil
                        }
                    }
                })
            }
        }
    }

    func cancelPrefetch(_ urls: [URL]) {
        engine.cancelPrefetch?(urls)
        self.prefetchTasks.withLockUnchecked { tasks in
            for url in urls {
                tasks.removeValue(forKey: url)?.task.cancel()
            }
        }
    }
}

package enum ImageLoader {
    private static let store = OSAllocatedUnfairLock<ImageLoaderCore?>(initialState: nil)

    package static func bootstrap(
        engine: ImageEngine,
        diskClient: FileClient,
        diskConfiguration: ImageDiskCacheConfiguration = .default
    ) {
        store.withLockUnchecked { current in
            precondition(current == nil, "ImageLoader는 프로세스당 1회만 부트스트랩한다")
            current = ImageLoaderCore(engine: engine, diskClient: diskClient, diskConfiguration: diskConfiguration)
        }
    }

    package static func load(
        _ url: URL,
        policy: ImageCachePolicy = .standard,
        targetPixelSize: CGSize? = nil
    ) async throws -> UIImage {
        try await core().load(url, policy: policy, targetPixelSize: targetPixelSize)
    }

    package static func prefetch(_ urls: [URL], targetPixelSize: CGSize? = nil) {
        core().prefetch(urls, targetPixelSize: targetPixelSize)
    }

    package static func cancelPrefetch(_ urls: [URL]) {
        core().cancelPrefetch(urls)
    }

    private static func core() -> ImageLoaderCore {
        guard let core = store.withLockUnchecked({ $0 }) else {
            fatalError("ImageLoader 미조립. App에서 bootstrap(engine:) 호출 필요")
        }
        return core
    }
}
