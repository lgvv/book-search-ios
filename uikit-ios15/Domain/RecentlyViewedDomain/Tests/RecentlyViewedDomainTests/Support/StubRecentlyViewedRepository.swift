import Foundation

import BookModel
import RecentlyViewedCore
import RecentlyViewedModel
import TestSupport

final class StubRecentlyViewedRepository: RecentlyViewedRepository, @unchecked Sendable {
    enum Call: Equatable {
        case list
        case record(isbn: String, maxCount: Int)
        case remove(isbn: String)
        case clear
    }

    struct Failure: Error, Equatable {
        let reason: String
    }

    let calls = Locked<[Call]>([])
    let listResult = Locked<Result<[ViewedBook], Failure>>(.success([]))
    private let writesFail = Locked(false)
    private let writeGate = Locked<Gate?>(nil)

    var listCallCount: Int {
        self.calls.value.filter { $0 == .list }.count
    }

    func failWrites() {
        self.writesFail.withValue { $0 = true }
    }

    @discardableResult
    func blockWrites() -> Gate {
        let gate = Gate()
        self.writeGate.withValue { $0 = gate }
        return gate
    }

    func list() async throws -> [ViewedBook] {
        self.calls.withValue { $0.append(.list) }
        return try self.listResult.value.get()
    }

    func record(book: Book, keeping maxCount: Int) async throws {
        try await self.perform(.record(isbn: book.isbn, maxCount: maxCount))
    }

    func remove(isbn: String) async throws {
        try await self.perform(.remove(isbn: isbn))
    }

    func clear() async throws {
        try await self.perform(.clear)
    }

    private func perform(_ call: Call) async throws {
        self.calls.withValue { $0.append(call) }
        if let gate = self.writeGate.value {
            await gate.wait()
        }
        if self.writesFail.value {
            throw Failure(reason: "쓰기 실패")
        }
    }
}
