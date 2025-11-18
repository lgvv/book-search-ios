import Foundation

@MainActor
public final class StateSubscriptions<State: Equatable> {
    private var observers: [(_ old: State, _ new: State) -> Void] = []

    public init() {}

    public func add<Value: Equatable>(
        scope: @escaping (State) -> Value,
        current state: State,
        render: @escaping (_ old: Value?, _ new: Value) -> Void
    ) {
        observers.append { old, new in
            let value = scope(new)
            let previous = scope(old)
            guard previous != value else { return }
            render(previous, value)
        }
        render(nil, scope(state))
    }

    public func notify(from old: State, to new: State) {
        guard old != new else { return }
        observers.forEach { $0(old, new) }
    }
}
