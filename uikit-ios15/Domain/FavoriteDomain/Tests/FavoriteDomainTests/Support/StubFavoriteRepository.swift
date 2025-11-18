import Foundation

import BookModel
import FavoriteCore
import TestSupport

final class StubFavoriteRepository: FavoriteRepository, @unchecked Sendable {
    enum Call: Equatable {
        case list
        case add(isbn: String)
        case remove(isbn: String)

        var isWrite: Bool { self != .list }

        var isbn: String? {
            switch self {
            case .list: nil
            case let .add(isbn), let .remove(isbn): isbn
            }
        }
    }

    struct Failure: Error, Equatable {
        let reason: String
    }

    let calls = Locked<[Call]>([])

    let listResult = Locked<Result<[Book], Failure>>(.success([]))

    let shouldFailWrite = Locked<(@Sendable (Call) -> Bool)?>(nil)

    let writeGates = Locked<[String: Gate]>([:])

    var writeCalls: [Call] {
        self.calls.value.filter(\.isWrite)
    }

    var listCallCount: Int {
        self.calls.value.filter { $0 == .list }.count
    }

    func failAllWrites() {
        self.shouldFailWrite.withValue { $0 = { _ in true } }
    }

    func failWrites(where predicate: @escaping @Sendable (Call) -> Bool) {
        self.shouldFailWrite.withValue { $0 = predicate }
    }

    @discardableResult
    func blockWrites(for isbn: String) -> Gate {
        let gate = Gate()
        self.writeGates.withValue { $0[isbn] = gate }
        return gate
    }

    func list() async throws -> [Book] {
        self.calls.withValue { $0.append(.list) }
        return try self.listResult.value.get()
    }

    func add(_ book: Book) async throws {
        try await self.perform(.add(isbn: book.isbn))
    }

    func remove(isbn: String) async throws {
        try await self.perform(.remove(isbn: isbn))
    }

    private func perform(_ call: Call) async throws {
        self.calls.withValue { $0.append(call) }

        if let isbn = call.isbn, let gate = self.writeGates.value[isbn] {
            await gate.wait()
        }
        if self.shouldFailWrite.value?(call) == true {
            throw Failure(reason: "쓰기 실패: \(call)")
        }
    }
}

extension Book {
    static func fixture(
        isbn: String = "9788937473135",
        title: String = "파친코",
        author: String? = "이민진",
        publisher: String? = "인플루엔셜"
    ) -> Book {
        Book(
            isbn: isbn,
            title: title,
            author: author,
            publisher: publisher,
            publishedAt: "2022.08.05",
            coverImageURL: URL(string: "https://picsum.photos/seed/\(isbn)/200/300")
        )
    }
}
