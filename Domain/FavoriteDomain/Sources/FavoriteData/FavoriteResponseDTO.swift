import Foundation

import BookModel

struct FavoriteItemDTO: Codable {
    let isbn: String
    let title: String
    let author: String?
    let publisher: String?
    let publishedAt: String?
    let coverImageURL: String?
    let createdAt: String?
}

struct FavoriteListResponseDTO: Decodable {
    let items: [FavoriteItemDTO]
}

extension FavoriteItemDTO {
    var asDomain: Book {
        Book(
            isbn: self.isbn,
            title: self.title,
            author: self.author,
            publisher: self.publisher,
            publishedAt: self.publishedAt,
            coverImageURL: self.coverImageURL.flatMap { $0.isEmpty ? nil : URL(string: $0) }
        )
    }
}
