import Foundation

public enum ResourceState<Value: Sendable>: Sendable {
    case loading
    case loaded(Value, isStale: Bool = false)
    case failed

    public var value: Value? {
        guard case let .loaded(value, _) = self else { return nil }
        return value
    }

    public var isStale: Bool {
        guard case let .loaded(_, isStale) = self else { return false }
        return isStale
    }
}

extension ResourceState: Equatable where Value: Equatable {}
