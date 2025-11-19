import Foundation

import BookModel

struct FetchBookUseCase: Sendable {
    let service: DefaultBookSearchService

    func callAsFunction(isbn: String) async throws -> Book? {
        try await service.book(isbn: isbn)
    }
}
