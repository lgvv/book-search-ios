import Foundation

public struct StorageKey<Value>: Sendable {
    public let rawValue: String

    public init(namespace: String, name: String) {
        self.rawValue = "\(namespace).\(name)"
    }
}

extension UserDefaultsClient {
    public func object<Value: Decodable>(_ key: StorageKey<Value>) -> Value? {
        self.object(Value.self, forKey: key.rawValue)
    }

    public func setObject<Value: Encodable>(_ value: Value, for key: StorageKey<Value>) {
        self.setObject(value, forKey: key.rawValue)
    }

    public func remove<Value>(_ key: StorageKey<Value>) {
        self.remove(key.rawValue)
    }
}

extension UserDefaultsClient {
    public func string(_ key: StorageKey<String>) -> String? {
        self.string(key.rawValue)
    }

    public func bool(_ key: StorageKey<Bool>) -> Bool? {
        self.bool(key.rawValue)
    }

    public func int(_ key: StorageKey<Int>) -> Int? {
        self.int(key.rawValue)
    }

    public func setString(_ value: String, for key: StorageKey<String>) {
        self.setString(value, key.rawValue)
    }

    public func setBool(_ value: Bool, for key: StorageKey<Bool>) {
        self.setBool(value, key.rawValue)
    }

    public func setInt(_ value: Int, for key: StorageKey<Int>) {
        self.setInt(value, key.rawValue)
    }
}
