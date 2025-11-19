import UIKit

extension ImagePipelineStage {
    static func diskCache(
        _ disk: DiskCache,
        decode: @escaping @Sendable (Data, _ pixelSize: CGSize?) async -> UIImage?
    ) -> Self {
        Self { context, next in
            guard context.behavior == .standard || context.behavior == .refresh else {
                return try await next(context)
            }

            if context.intent == .revalidate {
                do {
                    let outcome = try await next(context)
                    if let data = outcome.data {
                        await disk.store(data, etag: outcome.etag, for: context.url)
                    }
                    return outcome
                } catch ImagePipelineSignal.notModified {
                    if let generation = context.revalidatingGeneration {
                        disk.markRevalidated(for: context.url, etag: context.etag, generation: generation)
                    }
                    guard
                        let entry = await disk.entry(for: context.url),
                        let image = await decode(entry.data, context.targetPixelSize)
                    else {
                        throw ImageEngineError.decodingFailed
                    }
                    return ImageLoadOutcome(image: image, data: entry.data, etag: entry.etag, source: .disk)
                }
            }

            if context.behavior == .standard,
               let entry = await disk.entry(for: context.url), let image = await decode(entry.data, context.targetPixelSize) {
                var outcome = ImageLoadOutcome(image: image, data: entry.data, etag: entry.etag, source: .disk)
                if !entry.isFresh {
                    outcome.staleETag = .init(etag: entry.etag, generation: entry.generation)
                }
                return outcome
            }

            let outcome = try await next(context)
            if let data = outcome.data {
                await disk.store(data, etag: outcome.etag, for: context.url)
            }
            return outcome
        }
    }
}
