import Foundation

import BookModel

struct SaveMemoUseCase: Sendable {
    let service: DefaultMemoService

    func callAsFunction(_ book: Book, text: String) async throws {
        try await service.save(book, text: text)
    }
}
