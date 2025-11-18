import Foundation

import BookModel
import MemoCore
import MemoModel
import TestSupport

final class StubMemoRepository: MemoRepository, @unchecked Sendable {
    enum Call: Equatable {
        case list
        case save(isbn: String, text: String)
        case remove(isbn: String)

        var savedText: String? {
            guard case let .save(_, text) = self else { return nil }
            return text
        }

        var isbn: String? {
            switch self {
            case .list: nil
            case let .save(isbn, _), let .remove(isbn): isbn
            }
        }
    }

    struct Failure: Error, Equatable {
        let reason: String
    }

    let calls = Locked<[Call]>([])
    let listResult = Locked<Result<[BookMemo], Failure>>(.success([]))
    let saveResult = Locked<Result<Void, Failure>>(.success(()))

    private let saveGates = Locked<[String?: Gate]>([:])

    var listCallCount: Int {
        self.calls.value.filter { $0 == .list }.count
    }

    @discardableResult
    func blockSaves(for isbn: String? = nil) -> Gate {
        let gate = Gate()
        self.saveGates.withValue { $0[isbn] = gate }
        return gate
    }

    func list() async throws -> [BookMemo] {
        self.calls.withValue { $0.append(.list) }
        return try self.listResult.value.get()
    }

    func save(_ book: Book, text: String, updatedAt: Date) async throws {
        self.calls.withValue { $0.append(.save(isbn: book.isbn, text: text)) }

        let gate = self.saveGates.value[book.isbn] ?? self.saveGates.value[nil] ?? nil
        if let gate {
            await gate.wait()
        }
        try self.saveResult.value.get()
    }

    func remove(isbn: String) async throws {
        self.calls.withValue { $0.append(.remove(isbn: isbn)) }
        try self.saveResult.value.get()
    }
}

extension Book {
    static func fixture(
        isbn: String = "9788937473135",
        title: String = "파친코",
        author: String? = "이민진"
    ) -> Book {
        Book(
            isbn: isbn,
            title: title,
            author: author,
            publisher: "인플루엔셜",
            publishedAt: "2022.08.05",
            coverImageURL: URL(string: "https://picsum.photos/seed/\(isbn)/200/300")
        )
    }
}
