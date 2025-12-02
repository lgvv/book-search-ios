import Foundation

struct FavoriteItemServerDTO: Codable {
    let isbn: String
    let title: String
    let author: String?
    let publisher: String?
    let publishedAt: String?
    let coverImageURL: String?
    let createdAt: Date?
}

struct FavoriteListServerDTO: Encodable {
    let items: [FavoriteItemServerDTO]
}

extension FavoriteItemServerDTO {
    init(_ record: FavoriteRecord) {
        self.init(
            isbn: record.isbn,
            title: record.title,
            author: record.author,
            publisher: record.publisher,
            publishedAt: record.publishedAt,
            coverImageURL: record.coverImageURL,
            createdAt: record.createdAt
        )
    }

    func record(createdAt: Date) -> FavoriteRecord {
        FavoriteRecord(
            isbn: self.isbn,
            title: self.title,
            author: self.author,
            publisher: self.publisher,
            publishedAt: self.publishedAt,
            coverImageURL: self.coverImageURL,
            createdAt: createdAt
        )
    }
}
