import Foundation

import BookModel

struct BookSearchResponseDTO: Decodable {
    let items: [BookItemDTO]
    let page: Int
    let pageSize: Int
    let totalCount: Int
}

struct BookItemDTO: Decodable {
    let isbn: String
    let title: String
    let author: String?
    let publisher: String?
    let publishedAt: String?
    let coverImageURL: String?
}

extension BookItemDTO {
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
