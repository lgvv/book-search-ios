import Foundation

import SharedFoundation

public protocol ResolverKey<Value>: Sendable {
    associatedtype Value: Sendable

    static var testValue: Value { get }
}

public struct ResolverValues: Sendable {
    var storage: [ObjectIdentifier: any Sendable] = [:]

    public init() {}

    public subscript<K: ResolverKey>(key: K.Type) -> K.Value? {
        get { self.storage[ObjectIdentifier(key)] as? K.Value }
        set { self.storage[ObjectIdentifier(key)] = newValue }
    }
}

public enum ResolverBase: Sendable {
    case test

    case inheritingCurrent
}

public enum Resolver {
    struct Override: Sendable {
        var values: ResolverValues
        var allowsTestFallback: Bool
    }

    static let root = LockIsolated<ResolverValues?>(nil)

    @TaskLocal static var override: Override?

    public static func install(_ values: ResolverValues) {
        precondition(Self.override == nil, "override 스코프 안에서는 설치할 수 없다")
        Self.root.withValue { current in
            precondition(current == nil, "Resolver는 프로세스당 1회만 설치한다")
            current = values
        }
    }

    public static subscript<K: ResolverKey>(key: K.Type) -> K.Value {
        if let override = Self.override {
            if let value = override.values[key] {
                return value
            }
            guard override.allowsTestFallback else {
                preconditionFailure("live를 상속한 스코프에 없는 키: \(K.self). 조립 누락")
            }
            return K.testValue
        }
        guard let value = Self.root.value?[key] else {
            preconditionFailure("live root에 없는 키: \(K.self). install 전이거나 조립 누락")
        }
        return value
    }

    static func makeOverride(from base: ResolverBase) -> Override {
        switch base {
        case .test:
            return Override(values: ResolverValues(), allowsTestFallback: true)
        case .inheritingCurrent:
            if let current = Self.override {
                return current
            }
            return Override(values: Self.root.value ?? ResolverValues(), allowsTestFallback: false)
        }
    }
}

@propertyWrapper
public struct Resolved<Value: Sendable>: Sendable {
    public let wrappedValue: Value

    public init<K: ResolverKey>(_ key: K.Type) where K.Value == Value {
        self.wrappedValue = Resolver[key]
    }
}

public func withResolver<R>(
    from base: ResolverBase = .test,
    _ mutate: (inout ResolverValues) -> Void,
    operation: () throws -> R
) rethrows -> R {
    var override = Resolver.makeOverride(from: base)
    mutate(&override.values)
    return try Resolver.$override.withValue(override, operation: operation)
}

public func withResolver<R>(
    from base: ResolverBase = .test,
    _ mutate: (inout ResolverValues) -> Void,
    operation: () async throws -> R
) async rethrows -> R {
    var override = Resolver.makeOverride(from: base)
    mutate(&override.values)
    return try await Resolver.$override.withValue(override, operation: operation)
}
