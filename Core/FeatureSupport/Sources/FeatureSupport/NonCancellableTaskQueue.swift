import Foundation

@MainActor
public final class NonCancellableTaskQueue<ID: Hashable & Sendable> {
    private var tails: [ID: Task<Void, Never>] = [:]

    public init() {}

    public func enqueue(_ id: ID, operation: @escaping () async -> Void) {
        let previous = tails[id]
        tails[id] = Task {
            await previous?.value
            await operation()
        }
    }
}
