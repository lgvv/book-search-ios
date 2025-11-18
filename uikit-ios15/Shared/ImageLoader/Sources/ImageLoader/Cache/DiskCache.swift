import CryptoKit
import Foundation

import PersistenceInterface
import SharedFoundation

public struct ImageDiskCacheConfiguration: Sendable {
    public var maxByteSize: Int

    public var maxEntryByteSize: Int

    public var freshLifetime: TimeInterval

    public init(maxByteSize: Int, freshLifetime: TimeInterval, maxEntryByteSize: Int? = nil) {
        self.maxByteSize = maxByteSize
        self.freshLifetime = freshLifetime
        self.maxEntryByteSize = maxEntryByteSize ?? maxByteSize / 8
    }

    public static let `default` = Self(
        maxByteSize: 64 * 1024 * 1024,
        freshLifetime: 7 * 24 * 60 * 60
    )
}

struct DiskCacheEntry {
    let data: Data
    let etag: String?
    let generation: Int
    let isFresh: Bool
}

final class DiskCache: Sendable {
    private struct Metadata: Codable {
        var etag: String?
        var storedAt: Date
        var lastAccessedAt: Date
        var byteSize: Int
        var generation: Int
    }

    private struct Manifest: Codable {
        static let currentSchemaVersion = 1

        var schemaVersion: Int
        var entries: [String: Metadata]
    }

    private struct State {
        var entries: [String: Metadata] = [:]
        var pending: [String: Set<Int>] = [:]
        var nextGeneration: Int = 1
    }

    private static let manifestKey = "manifest.json"

    private let client: FileClient
    private let configuration: ImageDiskCacheConfiguration
    private let state: LockIsolated<State>
    private let io: FileIOQueue

    private let readiness: Task<Void, Never>

    private let isFlushScheduled = LockIsolated(false)

    init(client: FileClient, configuration: ImageDiskCacheConfiguration) {
        let state = LockIsolated(State())
        let io = FileIOQueue(label: "com.booksearch.imagecache.io")

        self.client = client
        self.configuration = configuration
        self.state = state
        self.io = io

        self.readiness = Task {
            await Self.prepare(client: client, io: io, state: state)
        }
    }

    func entry(for url: URL) async -> DiskCacheEntry? {
        await self.readiness.value
        let key = self.key(for: url)

        let metadata: Metadata? = self.state.withValue { state in
            guard var metadata = state.entries[key] else { return nil }
            metadata.lastAccessedAt = Date()
            state.entries[key] = metadata
            return metadata
        }
        guard let metadata else { return nil }
        self.scheduleManifestFlush()

        let fileKey = Self.fileKey(key, metadata.generation)
        let data = await self.io.run { [client] in client.data(fileKey) }

        guard let data else {
            self.state.withValue { state in
                if state.entries[key]?.generation == metadata.generation {
                    state.entries[key] = nil
                }
            }
            self.scheduleManifestFlush()
            return nil
        }

        return DiskCacheEntry(
            data: data,
            etag: metadata.etag,
            generation: metadata.generation,
            isFresh: Date().timeIntervalSince(metadata.storedAt) < self.configuration.freshLifetime
        )
    }

    func store(_ data: Data, etag: String?, for url: URL) async {
        guard data.count <= self.configuration.maxEntryByteSize else {
            return
        }

        await self.readiness.value
        let key = self.key(for: url)

        let generation = self.state.withValue { state -> Int in
            let next = state.nextGeneration
            state.nextGeneration += 1
            state.pending[key, default: []].insert(next)
            return next
        }

        let newFileKey = Self.fileKey(key, generation)
        let writeError: (any Error)? = await self.io.run { [client] in
            do {
                try client.setData(data, newFileKey)
                return nil
            } catch {
                return error
            }
        }

        let now = Date()
        let obsolete: [String] = self.state.withValue { state in
            state.pending[key]?.remove(generation)
            if state.pending[key]?.isEmpty == true {
                state.pending[key] = nil
            }

            guard writeError == nil else {
                return [newFileKey]
            }

            if let current = state.entries[key], current.generation > generation {
                return [newFileKey]
            }

            let previousGeneration = state.entries[key]?.generation
            state.entries[key] = Metadata(
                etag: etag,
                storedAt: now,
                lastAccessedAt: now,
                byteSize: data.count,
                generation: generation
            )

            var victims = Self.evictionVictims(
                &state.entries,
                keeping: key,
                maxByteSize: self.configuration.maxByteSize
            )
            if let previousGeneration, previousGeneration != generation {
                victims.append(Self.fileKey(key, previousGeneration))
            }
            return victims
        }

        if !obsolete.isEmpty {
            self.io.enqueue { [client] in
                for fileKey in obsolete {
                    try? client.remove(fileKey)
                }
            }
        }
        self.scheduleManifestFlush()
    }

    func markRevalidated(for url: URL, etag: String?, generation: Int) {
        let key = self.key(for: url)
        self.state.withValue { state in
            guard var metadata = state.entries[key], metadata.generation == generation else { return }
            metadata.storedAt = Date()
            if let etag {
                metadata.etag = etag
            }
            state.entries[key] = metadata
        }
        self.scheduleManifestFlush()
    }

    private static func evictionVictims(
        _ entries: inout [String: Metadata],
        keeping protected: String,
        maxByteSize: Int
    ) -> [String] {
        var total = entries.values.reduce(0) { $0 + $1.byteSize }
        guard total > maxByteSize else { return [] }

        var victims: [String] = []
        let candidates = entries
            .filter { $0.key != protected }
            .sorted { $0.value.lastAccessedAt < $1.value.lastAccessedAt }

        for (key, metadata) in candidates where total > maxByteSize {
            entries[key] = nil
            total -= metadata.byteSize
            victims.append(Self.fileKey(key, metadata.generation))
        }
        return victims
    }

    private static func prepare(
        client: FileClient,
        io: FileIOQueue,
        state: LockIsolated<State>
    ) async {
        _ = await io.run { () -> (discardedManifest: Bool, removed: Int) in
            let manifest = client.data(Self.manifestKey)
                .flatMap { try? JSONDecoder().decode(Manifest.self, from: $0) }
            let isCompatible = manifest?.schemaVersion == Manifest.currentSchemaVersion
            let entries = isCompatible ? (manifest?.entries ?? [:]) : [:]

            let existing = (try? client.keys()) ?? []
            let highestOnDisk = existing.compactMap(Self.generation(ofFileKey:)).max() ?? 0
            let highestInManifest = entries.values.map(\.generation).max() ?? 0

            let live: Set<String> = state.withValue { state in
                state.entries = entries
                state.nextGeneration = max(highestInManifest, highestOnDisk) + 1

                var live = Set([Self.manifestKey])
                for (key, metadata) in entries {
                    live.insert(Self.fileKey(key, metadata.generation))
                }
                for (key, generations) in state.pending {
                    for generation in generations {
                        live.insert(Self.fileKey(key, generation))
                    }
                }
                return live
            }

            var removed = 0
            for orphan in existing where !live.contains(orphan) {
                if (try? client.remove(orphan)) != nil { removed += 1 }
            }
            return (manifest != nil && !isCompatible, removed)
        }
    }

    private static func generation(ofFileKey fileKey: String) -> Int? {
        guard let separator = fileKey.lastIndex(of: ".") else { return nil }
        return Int(fileKey[fileKey.index(after: separator)...])
    }

    private func scheduleManifestFlush() {
        let alreadyScheduled = self.isFlushScheduled.withValue { scheduled -> Bool in
            if scheduled { return true }
            scheduled = true
            return false
        }
        guard !alreadyScheduled else { return }

        self.io.enqueue { [isFlushScheduled, state, client] in
            isFlushScheduled.withValue { $0 = false }
            let manifest = Manifest(
                schemaVersion: Manifest.currentSchemaVersion,
                entries: state.value.entries
            )
            guard let encoded = try? JSONEncoder().encode(manifest) else { return }
            try? client.setData(encoded, Self.manifestKey)
        }
    }

    private static func fileKey(_ key: String, _ generation: Int) -> String {
        "\(key).\(generation)"
    }

    private func key(for url: URL) -> String {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
