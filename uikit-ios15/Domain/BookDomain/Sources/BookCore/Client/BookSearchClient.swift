import Foundation

import BookModel
import DependencyResolver

public struct BookSearchClient: Sendable {
    public var search: @Sendable (_ query: String, _ page: Int) async throws -> SearchPage
    public var book: @Sendable (_ isbn: String) async throws -> Book?

    public init(
        search: @escaping @Sendable (_ query: String, _ page: Int) async throws -> SearchPage,
        book: @escaping @Sendable (_ isbn: String) async throws -> Book?
    ) {
        self.search = search
        self.book = book
    }
}

extension BookSearchClient {
    public static var testValue: Self {
        Self(
            search: { _, _ in fatalError("unimplemented: BookSearchClient.search") },
            book: { _ in fatalError("unimplemented: BookSearchClient.book") }
        )
    }
}

public enum BookSearchClientKey: ResolverKey {
    public static var testValue: BookSearchClient { .testValue }
}
