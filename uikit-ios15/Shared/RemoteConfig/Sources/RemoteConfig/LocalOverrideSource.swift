import Foundation

import PersistenceInterface
import RemoteConfigInterface

public struct LocalOverrideSource: ConfigSource {
    private let client: UserDefaultsClient
    private let namespace: String

    public init(client: UserDefaultsClient, namespace: String) {
        self.client = client
        self.namespace = namespace
    }

    public func rawValue(forKey key: String) -> String? {
        self.client.string(self.storageKey(for: key))
    }

    public func setOverride<V: ConfigValue>(_ value: V?, for config: ConfigKey<V>) {
        let key = self.storageKey(for: config.key)
        if let value {
            self.client.setString(value.configRawValue, for: key)
        } else {
            self.client.remove(key)
        }
    }

    private func storageKey(for configKey: String) -> StorageKey<String> {
        StorageKey(namespace: self.namespace, name: configKey)
    }
}
