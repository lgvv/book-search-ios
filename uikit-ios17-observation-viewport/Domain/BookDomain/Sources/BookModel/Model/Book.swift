import Foundation

public struct Book: Sendable, Hashable, Identifiable {
    public var id: String { isbn }
    public let isbn: String
    public let title: String
    public let author: String?
    public let publisher: String?
    public let publishedAt: String?
    public let coverImageURL: URL?

    public init(
        isbn: String,
        title: String,
        author: String? = nil,
        publisher: String? = nil,
        publishedAt: String? = nil,
        coverImageURL: URL? = nil
    ) {
        self.isbn = isbn
        self.title = title
        self.author = author
        self.publisher = publisher
        self.publishedAt = publishedAt
        self.coverImageURL = coverImageURL
    }
}
