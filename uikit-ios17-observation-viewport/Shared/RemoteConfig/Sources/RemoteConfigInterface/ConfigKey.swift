import Foundation

public struct ConfigKey<Value: ConfigValue>: Sendable {
    public let key: String
    public let defaultValue: Value

    public let owner: String

    public init(key: String, defaultValue: Value, owner: String) {
        self.key = key
        self.defaultValue = defaultValue
        self.owner = owner
    }
}
