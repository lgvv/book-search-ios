import Foundation

import BookModel

extension BookSearchClient {
    public static func liveValue(repository: any BookRepository) -> Self {
        let service = DefaultBookSearchService(repository: repository)
        let searchBooks = SearchBooksUseCase(service: service)
        let fetchBook = FetchBookUseCase(service: service)
        return BookSearchClient(
            search: { try await searchBooks(query: $0, page: $1) },
            book: { try await fetchBook(isbn: $0) }
        )
    }
}
