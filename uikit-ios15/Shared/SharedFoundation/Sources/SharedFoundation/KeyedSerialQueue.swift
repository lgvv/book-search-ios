import Foundation

public final class KeyedSerialQueue<Key: Hashable & Sendable>: Sendable {
    private let tails = LockIsolated([Key: Task<Void, Never>]())

    public init() {}

    var trackedKeyCount: Int {
        self.tails.value.count
    }

    @discardableResult
    public func enqueue<R: Sendable>(
        _ key: Key,
        _ operation: @escaping @Sendable () async throws -> R
    ) -> Task<R, any Error> {
        self.tails.withValue { tails in
            let previous = tails[key]
            let task = Task<R, any Error> {
                await previous?.value
                return try await operation()
            }
            let tail = Task<Void, Never> { _ = try? await task.value }
            tails[key] = tail

            Task { [tails = self.tails] in
                await tail.value
                tails.withValue { current in
                    if current[key] == tail {
                        current[key] = nil
                    }
                }
            }
            return task
        }
    }
}
