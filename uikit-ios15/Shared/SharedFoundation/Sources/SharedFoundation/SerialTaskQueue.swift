import Foundation

public final class SerialTaskQueue: Sendable {
    private let tail = LockIsolated<Task<Void, Never>?>(nil)

    public init() {}

    @discardableResult
    public func enqueue<R: Sendable>(
        _ operation: @escaping @Sendable () async throws -> R
    ) -> Task<R, any Error> {
        self.tail.withValue { tail in
            let previous = tail
            let task = Task<R, any Error> {
                await previous?.value
                return try await operation()
            }
            tail = Task { _ = try? await task.value }
            return task
        }
    }
}
