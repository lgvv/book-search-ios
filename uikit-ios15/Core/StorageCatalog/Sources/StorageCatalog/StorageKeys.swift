import Foundation

import PersistenceInterface

public enum StorageKeys {

    public static let recentSearchTerms = StorageKey<[String]>(
        namespace: "recentSearch",
        name: "terms"
    )

    public static let remoteConfigSnapshot = StorageKey<[String: String]>(
        namespace: "remoteConfig",
        name: "snapshot"
    )

    public static let configOverrideNamespace = "config.override"
}
