import Foundation

import BookModel

public struct ViewedBook: Sendable, Hashable, Identifiable {
    public let book: Book
    public let viewedAt: Date

    public var id: String { book.isbn }

    public init(book: Book, viewedAt: Date) {
        self.book = book
        self.viewedAt = viewedAt
    }
}
