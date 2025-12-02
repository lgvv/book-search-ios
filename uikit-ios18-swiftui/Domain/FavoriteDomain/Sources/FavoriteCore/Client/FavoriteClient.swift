import Foundation

import BookModel
import DependencyResolver
import SharedFoundation

public struct FavoriteClient: Sendable {
    public var submitAdd: @Sendable (Book) async -> Void
    public var submitRemove: @Sendable (_ isbn: String) async -> Void
    public var list: @Sendable () async -> [Book]
    public var isFavorite: @Sendable (_ isbn: String) async -> Bool
    public var observe: @Sendable () -> AsyncStream<ResourceState<[Book]>>
    public var observeFailures: @Sendable () -> AsyncStream<FavoriteWriteFailure>
    public var reload: @Sendable () async -> Void
    public var start: @Sendable () async -> Void

    public init(
        submitAdd: @escaping @Sendable (Book) async -> Void,
        submitRemove: @escaping @Sendable (_ isbn: String) async -> Void,
        list: @escaping @Sendable () async -> [Book],
        isFavorite: @escaping @Sendable (_ isbn: String) async -> Bool,
        observe: @escaping @Sendable () -> AsyncStream<ResourceState<[Book]>>,
        observeFailures: @escaping @Sendable () -> AsyncStream<FavoriteWriteFailure>,
        reload: @escaping @Sendable () async -> Void,
        start: @escaping @Sendable () async -> Void
    ) {
        self.submitAdd = submitAdd
        self.submitRemove = submitRemove
        self.list = list
        self.isFavorite = isFavorite
        self.observe = observe
        self.observeFailures = observeFailures
        self.reload = reload
        self.start = start
    }
}

extension FavoriteClient {
    public static var testValue: Self {
        Self(
            submitAdd: { _ in fatalError("unimplemented: FavoriteClient.submitAdd") },
            submitRemove: { _ in fatalError("unimplemented: FavoriteClient.submitRemove") },
            list: { fatalError("unimplemented: FavoriteClient.list") },
            isFavorite: { _ in fatalError("unimplemented: FavoriteClient.isFavorite") },
            observe: { fatalError("unimplemented: FavoriteClient.observe") },
            observeFailures: { fatalError("unimplemented: FavoriteClient.observeFailures") },
            reload: { fatalError("unimplemented: FavoriteClient.reload") },
            start: { fatalError("unimplemented: FavoriteClient.start") }
        )
    }
}

public enum FavoriteClientKey: ResolverKey {
    public static var testValue: FavoriteClient { .testValue }
}
