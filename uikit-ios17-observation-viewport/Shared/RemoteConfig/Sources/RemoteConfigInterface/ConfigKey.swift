import Foundation

public struct ConfigKey<Value: ConfigValue>: Sendable {
    public let key: String
    public let defaultValue: Value

    public let owner: String

    public let isValid: @Sendable (Value) -> Bool

    public init(
        key: String,
        defaultValue: Value,
        owner: String,
        isValid: @escaping @Sendable (Value) -> Bool = { _ in true }
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.owner = owner
        self.isValid = isValid
    }
}
