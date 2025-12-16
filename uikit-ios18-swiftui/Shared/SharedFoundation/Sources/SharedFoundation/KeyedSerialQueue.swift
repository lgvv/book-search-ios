import Foundation
import Synchronization

public final class KeyedSerialQueue<Key: Hashable & Sendable>: Sendable {
    private let tails = Mutex([Key: Task<Void, Never>]())

    public init() {}

    var trackedKeyCount: Int {
        self.tails.withLock { $0.count }
    }

    @discardableResult
    public func enqueue<R: Sendable>(
        _ key: Key,
        _ operation: @escaping @Sendable () async throws -> R
    ) -> Task<R, any Error> {
        self.tails.withLock { tails in
            let previous = tails[key]
            let task = Task<R, any Error> {
                await previous?.value
                return try await operation()
            }
            let tail = Task<Void, Never> { _ = try? await task.value }
            tails[key] = tail

            Task { [weak self] in
                await tail.value
                self?.tails.withLock { current in
                    if current[key] == tail {
                        current[key] = nil
                    }
                }
            }
            return task
        }
    }
}
