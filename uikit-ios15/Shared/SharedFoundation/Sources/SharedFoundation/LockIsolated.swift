import Foundation

public final class LockIsolated<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: Value

    public init(_ value: Value) {
        self._value = value
    }

    public var value: Value {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self._value
    }

    public func withValue<R>(_ operation: (inout Value) throws -> R) rethrows -> R {
        self.lock.lock()
        defer { self.lock.unlock() }
        return try operation(&self._value)
    }
}
