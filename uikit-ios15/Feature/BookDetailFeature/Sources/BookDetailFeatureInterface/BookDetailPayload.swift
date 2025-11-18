import Foundation

import BookModel

public struct BookDetailPayload: Sendable, Equatable {
    public let book: Book
    public let isFavorite: Bool
    public let memoText: String

    public init(book: Book, isFavorite: Bool, memoText: String) {
        self.book = book
        self.isFavorite = isFavorite
        self.memoText = memoText
    }
}
