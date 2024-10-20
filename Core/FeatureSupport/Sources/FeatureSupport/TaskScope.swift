import Foundation

@MainActor
public final class TaskScope<ID: Hashable & Sendable> {
    private struct Entry {
        let token: UUID
        let task: Task<Void, Never>
    }

    private var tasks: [ID: Entry] = [:]

    public init() {}

    deinit {
        tasks.values.forEach { $0.task.cancel() }
    }

    public func run(_ id: ID, operation: @escaping () async -> Void) {
        tasks[id]?.task.cancel()

        let token = UUID()
        tasks[id] = Entry(
            token: token,
            task: Task { [weak self] in
                await operation()
                guard self?.tasks[id]?.token == token else { return }
                self?.tasks[id] = nil
            }
        )
    }

    public func cancel(_ id: ID) {
        tasks[id]?.task.cancel()
        tasks[id] = nil
    }

    public func cancelAll() {
        tasks.values.forEach { $0.task.cancel() }
        tasks.removeAll()
    }
}
