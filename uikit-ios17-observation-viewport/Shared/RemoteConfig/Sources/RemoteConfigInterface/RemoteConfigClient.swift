import Foundation

public struct RemoteConfigClient: Sendable {
    public var rawValues: @Sendable (_ key: String) -> [String]

    public init(rawValues: @escaping @Sendable (_ key: String) -> [String]) {
        self.rawValues = rawValues
    }
}

extension RemoteConfigClient {
    public func value<V: ConfigValue>(_ config: ConfigKey<V>) -> V {
        for raw in self.rawValues(config.key) {
            if let value = V(configRawValue: raw), config.isValid(value) {
                return value
            }
        }
        return config.defaultValue
    }
}
