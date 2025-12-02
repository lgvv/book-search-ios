import Foundation

public final class AsyncValueChannel<Value: Sendable>: Sendable {
    private struct State {
        var value: Value
        var continuations: [UUID: AsyncStream<Value>.Continuation] = [:]
    }

    private let state: LockIsolated<State>

    public init(_ initialValue: Value) {
        self.state = LockIsolated(State(value: initialValue))
    }

    deinit {
        self.state.withValue { state in
            for continuation in state.continuations.values {
                continuation.finish()
            }
        }
    }

    public var value: Value {
        self.state.withValue { $0.value }
    }

    public func send(_ value: Value) {
        self.state.withValue { state in
            state.value = value
            for continuation in state.continuations.values {
                continuation.yield(value)
            }
        }
    }

    public func stream() -> AsyncStream<Value> {
        let id = UUID()
        let (stream, continuation) = AsyncStream.makeStream(
            of: Value.self,
            bufferingPolicy: .bufferingNewest(64)
        )
        self.state.withValue { state in
            continuation.yield(state.value)
            state.continuations[id] = continuation
        }
        continuation.onTermination = { [weak self] _ in
            self?.state.withValue { _ = $0.continuations.removeValue(forKey: id) }
        }
        return stream
    }
}
