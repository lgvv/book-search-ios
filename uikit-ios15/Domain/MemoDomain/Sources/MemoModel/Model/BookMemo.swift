import Foundation

import BookModel

public struct BookMemo: Sendable, Hashable, Identifiable {
    public let book: Book
    public let text: String
    public let updatedAt: Date

    public var id: String { book.isbn }

    public init(book: Book, text: String, updatedAt: Date) {
        self.book = book
        self.text = text
        self.updatedAt = updatedAt
    }
}
