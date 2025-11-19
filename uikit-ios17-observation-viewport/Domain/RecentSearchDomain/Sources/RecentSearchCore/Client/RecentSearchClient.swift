import Foundation

import DependencyResolver

public struct RecentSearchClient: Sendable {
    public var record: @Sendable (String) async -> Void
    public var list: @Sendable () async -> [String]
    public var remove: @Sendable (String) async -> Void

    public init(
        record: @escaping @Sendable (String) async -> Void,
        list: @escaping @Sendable () async -> [String],
        remove: @escaping @Sendable (String) async -> Void
    ) {
        self.record = record
        self.list = list
        self.remove = remove
    }
}

extension RecentSearchClient {
    public static var testValue: Self {
        Self(
            record: { _ in fatalError("unimplemented: RecentSearchClient.record") },
            list: { fatalError("unimplemented: RecentSearchClient.list") },
            remove: { _ in fatalError("unimplemented: RecentSearchClient.remove") }
        )
    }
}

public enum RecentSearchClientKey: ResolverKey {
    public static var testValue: RecentSearchClient { .testValue }
}
