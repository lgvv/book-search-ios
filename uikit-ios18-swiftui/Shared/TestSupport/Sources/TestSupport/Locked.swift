import os

public struct Locked<Value>: Sendable {
    private let storage: OSAllocatedUnfairLock<Value>

    public init(_ value: Value) {
        self.storage = OSAllocatedUnfairLock(uncheckedState: value)
    }

    public var value: Value {
        self.storage.withLockUnchecked { $0 }
    }

    @discardableResult
    public func withValue<R>(_ operation: (inout Value) throws -> R) rethrows -> R {
        try self.storage.withLockUnchecked(operation)
    }
}

extension Locked where Value: AdditiveArithmetic {
    public func increment(by amount: Value) {
        self.withValue { $0 += amount }
    }
}
