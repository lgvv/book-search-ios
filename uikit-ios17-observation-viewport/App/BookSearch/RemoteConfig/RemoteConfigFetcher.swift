import Foundation

import StorageCatalog
import PersistenceInterface
import RemoteConfig

enum RemoteConfigFetcher {
    static func fetchForNextLaunch(client: UserDefaultsClient) {
        let payload: [String: String] = [
            "search.pageSize": "30",
        ]
        SnapshotSource.save(payload, client: client, key: StorageKeys.remoteConfigSnapshot)
    }
}
