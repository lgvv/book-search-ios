import Foundation

import BookModel

public protocol BookRepository: Sendable {
    func search(query: String, page: Int) async throws -> SearchPage
    func book(isbn: String) async throws -> Book?
}

struct DefaultBookSearchService: Sendable {
    let repository: any BookRepository

    func search(query: String, page: Int) async throws -> SearchPage {
        try await repository.search(query: query, page: page)
    }

    func book(isbn: String) async throws -> Book? {
        try await repository.book(isbn: isbn)
    }
}
