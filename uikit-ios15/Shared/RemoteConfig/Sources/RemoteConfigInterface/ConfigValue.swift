import Foundation

public protocol ConfigValue: Sendable {
    init?(configRawValue: String)
    var configRawValue: String { get }
}

extension String: ConfigValue {
    public init?(configRawValue: String) { self = configRawValue }
    public var configRawValue: String { self }
}

extension Bool: ConfigValue {
    public init?(configRawValue: String) { self.init(configRawValue) }
    public var configRawValue: String { String(self) }
}

extension Int: ConfigValue {
    public init?(configRawValue: String) { self.init(configRawValue) }
    public var configRawValue: String { String(self) }
}

extension Double: ConfigValue {
    public init?(configRawValue: String) { self.init(configRawValue) }
    public var configRawValue: String { String(self) }
}
