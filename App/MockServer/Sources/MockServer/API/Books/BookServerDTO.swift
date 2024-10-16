import Foundation

struct BookItemServerDTO: Encodable {
    let isbn: String
    let title: String
    let author: String?
    let publisher: String?
    let publishedAt: String?
    let coverImageURL: String?
}

struct BookSearchServerDTO: Encodable {
    let items: [BookItemServerDTO]
    let page: Int
    let pageSize: Int
    let totalCount: Int
}

extension BookItemServerDTO {
    init(_ record: BookRecord) {
        self.init(
            isbn: record.isbn,
            title: record.title,
            author: record.author,
            publisher: record.publisher,
            publishedAt: record.publishedAt,
            coverImageURL: record.coverImageURL
        )
    }
}
