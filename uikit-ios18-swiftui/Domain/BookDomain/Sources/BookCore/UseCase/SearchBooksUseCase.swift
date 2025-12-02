import Foundation

import BookModel

struct SearchBooksUseCase: Sendable {
    let service: DefaultBookSearchService

    func callAsFunction(query: String, page: Int) async throws -> SearchPage {
        try await service.search(query: query, page: page)
    }
}
