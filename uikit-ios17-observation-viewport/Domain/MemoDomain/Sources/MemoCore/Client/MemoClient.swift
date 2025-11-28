import Foundation

import BookModel
import DependencyResolver
import MemoModel
import SharedFoundation

public struct MemoClient: Sendable {
    public var save: @Sendable (Book, _ text: String) async throws -> Void
    public var list: @Sendable () async -> [BookMemo]
    public var memo: @Sendable (_ isbn: String) async throws -> MemoLookup
    public var observe: @Sendable () -> AsyncStream<ResourceState<[BookMemo]>>
    public var reload: @Sendable () async -> Void
    public var start: @Sendable () async -> Void

    public init(
        save: @escaping @Sendable (Book, _ text: String) async throws -> Void,
        list: @escaping @Sendable () async -> [BookMemo],
        memo: @escaping @Sendable (_ isbn: String) async throws -> MemoLookup,
        observe: @escaping @Sendable () -> AsyncStream<ResourceState<[BookMemo]>>,
        reload: @escaping @Sendable () async -> Void,
        start: @escaping @Sendable () async -> Void
    ) {
        self.save = save
        self.list = list
        self.memo = memo
        self.observe = observe
        self.reload = reload
        self.start = start
    }
}

extension MemoClient {
    public static var testValue: Self {
        Self(
            save: { _, _ in fatalError("unimplemented: MemoClient.save") },
            list: { fatalError("unimplemented: MemoClient.list") },
            memo: { _ in fatalError("unimplemented: MemoClient.memo") },
            observe: { fatalError("unimplemented: MemoClient.observe") },
            reload: { fatalError("unimplemented: MemoClient.reload") },
            start: { fatalError("unimplemented: MemoClient.start") }
        )
    }
}

public enum MemoClientKey: ResolverKey {
    public static var testValue: MemoClient { .testValue }
}
