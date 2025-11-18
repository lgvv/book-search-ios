import Foundation

public struct SearchPage: Sendable, Equatable {
    public let books: [Book]
    public let pageNo: Int
    public let totalCount: Int
    public let hasNext: Bool

    public init(books: [Book], pageNo: Int, totalCount: Int, hasNext: Bool) {
        self.books = books
        self.pageNo = pageNo
        self.totalCount = totalCount
        self.hasNext = hasNext
    }
}
