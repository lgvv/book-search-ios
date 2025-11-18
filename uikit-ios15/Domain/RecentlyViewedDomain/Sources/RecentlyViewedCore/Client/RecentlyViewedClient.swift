import Combine
import Foundation

import BookModel
import DependencyResolver
import RecentlyViewedModel
import SharedFoundation

public struct RecentlyViewedClient: Sendable {
    public var record: @Sendable (Book) async -> Void
    public var list: @Sendable () async -> [ViewedBook]
    public var remove: @Sendable (_ isbn: String) async -> Void
    public var clear: @Sendable () async -> Void
    public var observe: @Sendable () -> AnyPublisher<ResourceState<[ViewedBook]>, Never>
    public var reload: @Sendable () async -> Void
    public var start: @Sendable () async -> Void

    public init(
        record: @escaping @Sendable (Book) async -> Void,
        list: @escaping @Sendable () async -> [ViewedBook],
        remove: @escaping @Sendable (_ isbn: String) async -> Void,
        clear: @escaping @Sendable () async -> Void,
        observe: @escaping @Sendable () -> AnyPublisher<ResourceState<[ViewedBook]>, Never>,
        reload: @escaping @Sendable () async -> Void,
        start: @escaping @Sendable () async -> Void
    ) {
        self.record = record
        self.list = list
        self.remove = remove
        self.clear = clear
        self.observe = observe
        self.reload = reload
        self.start = start
    }
}

extension RecentlyViewedClient {
    public static var testValue: Self {
        Self(
            record: { _ in fatalError("unimplemented: RecentlyViewedClient.record") },
            list: { fatalError("unimplemented: RecentlyViewedClient.list") },
            remove: { _ in fatalError("unimplemented: RecentlyViewedClient.remove") },
            clear: { fatalError("unimplemented: RecentlyViewedClient.clear") },
            observe: { fatalError("unimplemented: RecentlyViewedClient.observe") },
            reload: { fatalError("unimplemented: RecentlyViewedClient.reload") },
            start: { fatalError("unimplemented: RecentlyViewedClient.start") }
        )
    }
}

public enum RecentlyViewedClientKey: ResolverKey {
    public static var testValue: RecentlyViewedClient { .testValue }
}
