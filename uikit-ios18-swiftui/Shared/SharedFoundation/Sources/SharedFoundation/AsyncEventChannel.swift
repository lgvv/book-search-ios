import Foundation
import Synchronization

public final class AsyncEventChannel<Value: Sendable>: Sendable {
    private let continuations = Mutex([UUID: AsyncStream<Value>.Continuation]())

    public init() {}

    deinit {
        self.continuations.withLock { continuations in
            for continuation in continuations.values {
                continuation.finish()
            }
        }
    }

    public func send(_ value: Value) {
        self.continuations.withLock { continuations in
            for continuation in continuations.values {
                continuation.yield(value)
            }
        }
    }

    public func stream() -> AsyncStream<Value> {
        let id = UUID()
        let (stream, continuation) = AsyncStream.makeStream(
            of: Value.self,
            bufferingPolicy: .unbounded
        )
        self.continuations.withLock { $0[id] = continuation }
        continuation.onTermination = { [weak self] _ in
            self?.continuations.withLock { _ = $0.removeValue(forKey: id) }
        }
        return stream
    }
}
