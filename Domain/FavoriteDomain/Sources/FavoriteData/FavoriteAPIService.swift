import Foundation

import BookModel
import NetworksInterface

struct FavoriteAPIService: Sendable {
    let baseURL: URL

    func listRequest() -> HTTPRequest {
        HTTPRequest(method: .get, url: self.favoritesURL)
    }

    func addRequest(_ book: Book) throws -> HTTPRequest {
        let dto = FavoriteItemDTO(
            isbn: book.isbn,
            title: book.title,
            author: book.author,
            publisher: book.publisher,
            publishedAt: book.publishedAt,
            coverImageURL: book.coverImageURL?.absoluteString,
            createdAt: nil
        )
        return HTTPRequest(
            method: .post,
            url: self.favoritesURL,
            headers: ["Content-Type": "application/json"],
            body: try JSONEncoder().encode(dto)
        )
    }

    func removeRequest(isbn: String) -> HTTPRequest {
        HTTPRequest(method: .delete, url: self.favoritesURL.appendingPathComponent(isbn))
    }

    private var favoritesURL: URL {
        self.baseURL.appendingPathComponent("v1/favorites")
    }
}
