import Foundation

struct BookCatalog: Sendable {
    private let books: [BookRecord]

    init(books: [BookRecord] = BookCatalogData.all) {
        self.books = books
    }

    func search(query: String, page: Int, size: Int) -> (items: [BookRecord], totalCount: Int) {
        let matches = self.matches(for: query)
        return (Self.page(of: matches, number: page, size: size), matches.count)
    }

    func book(isbn: String) -> BookRecord? {
        self.books.first { $0.isbn == isbn }
    }

    private func matches(for query: String) -> [BookRecord] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return [] }

        var scored: [(book: BookRecord, rank: Int)] = []
        for book in self.books {
            guard let rank = Self.relevance(of: book, matching: needle) else { continue }
            scored.append((book: book, rank: rank))
        }

        scored.sort { left, right in
            if left.rank != right.rank { return left.rank < right.rank }
            return (left.book.publishedAt ?? "") > (right.book.publishedAt ?? "")
        }
        return scored.map(\.book)
    }

    private static func relevance(of book: BookRecord, matching needle: String) -> Int? {
        let title = book.title.lowercased()
        if title == needle { return 0 }
        if title.hasPrefix(needle) { return 1 }
        if title.contains(needle) { return 2 }
        if book.author?.lowercased().contains(needle) == true { return 3 }
        if book.publisher?.lowercased().contains(needle) == true { return 4 }
        return nil
    }

    private static func page(of books: [BookRecord], number: Int, size: Int) -> [BookRecord] {
        guard size > 0, number > 0, number - 1 <= books.count / size else { return [] }

        let startIndex = (number - 1) * size
        guard startIndex < books.count else { return [] }
        return Array(books[startIndex..<min(startIndex + size, books.count)])
    }
}

struct BookRecord: Sendable {
    let isbn: String
    let title: String
    let author: String?
    let publisher: String?
    let publishedAt: String?
    let coverImageURL: String?
}
