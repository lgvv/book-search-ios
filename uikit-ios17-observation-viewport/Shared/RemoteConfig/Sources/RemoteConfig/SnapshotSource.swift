import Foundation

import PersistenceInterface
import RemoteConfigInterface

public struct SnapshotSource: ConfigSource {
    private let values: [String: String]

    public init(client: UserDefaultsClient, key: StorageKey<[String: String]>) {
        self.values = client.object(key) ?? [:]
    }

    public func rawValue(forKey key: String) -> String? {
        self.values[key]
    }

    public static func save(
        _ payload: [String: String],
        client: UserDefaultsClient,
        key: StorageKey<[String: String]>
    ) {
        client.setObject(payload, for: key)
    }
}
