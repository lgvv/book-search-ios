import XCTest

import BookModel
import MemoCore
import MemoModel
import Persistence
import PersistenceInterface

@testable import MemoData

final class DefaultMemoRepositoryTests: XCTestCase {

    private let pachinko = Book(isbn: "1", title: "파친코", author: "이민진")
    private let toji = Book(isbn: "2", title: "토지", author: "박경리")

    private var sut: (any MemoRepository)!

    override func setUp() {
        super.setUp()
        self.sut = makeMemoRepository(storeFactory: .inMemory)
    }

    func test_저장한메모를_목록에서읽을수있다() async throws {
        let updatedAt = Date()

        try await self.sut.save(pachinko, text: "좋았다", updatedAt: updatedAt)

        let memos = try await self.sut.list()
        XCTAssertEqual(memos.count, 1)
        XCTAssertEqual(memos.first?.text, "좋았다")
        XCTAssertEqual(memos.first?.book.isbn, pachinko.isbn)
    }

    func test_책정보를_함께보관한다() async throws {
        let book = Book(
            isbn: "1",
            title: "파친코",
            author: "이민진",
            publisher: "인플루엔셜",
            publishedAt: "2022.08.05",
            coverImageURL: URL(string: "https://example.com/1.jpg")
        )

        try await self.sut.save(book, text: "좋았다", updatedAt: Date())

        let memos = try await self.sut.list()
        XCTAssertEqual(memos.first?.book, book)
    }

    func test_저장한메모가없으면_빈목록이다() async throws {
        let memos = try await self.sut.list()

        XCTAssertEqual(memos, [])
    }

    func test_같은책에다시저장하면_새항목을만들지않고내용을바꾼다() async throws {
        try await self.sut.save(pachinko, text: "처음", updatedAt: Date(timeIntervalSince1970: 100))

        try await self.sut.save(pachinko, text: "고침", updatedAt: Date(timeIntervalSince1970: 200))

        let memos = try await self.sut.list()
        XCTAssertEqual(memos.count, 1)
        XCTAssertEqual(memos.first?.text, "고침")
    }

    func test_같은책에다시저장하면_updatedAt도갱신된다() async throws {
        try await self.sut.save(pachinko, text: "처음", updatedAt: Date(timeIntervalSince1970: 100))
        let later = Date(timeIntervalSince1970: 200)

        try await self.sut.save(pachinko, text: "고침", updatedAt: later)

        let memos = try await self.sut.list()
        XCTAssertEqual(memos.first?.updatedAt, later)
    }

    func test_목록은_최근수정순으로내려온다() async throws {
        try await self.sut.save(toji, text: "먼저", updatedAt: Date(timeIntervalSince1970: 100))
        try await self.sut.save(pachinko, text: "나중", updatedAt: Date(timeIntervalSince1970: 200))

        let memos = try await self.sut.list()

        XCTAssertEqual(memos.map(\.book.isbn), [pachinko.isbn, toji.isbn])
    }

    func test_오래된메모를수정하면_목록맨앞으로올라온다() async throws {
        try await self.sut.save(toji, text: "먼저", updatedAt: Date(timeIntervalSince1970: 100))
        try await self.sut.save(pachinko, text: "나중", updatedAt: Date(timeIntervalSince1970: 200))

        try await self.sut.save(toji, text: "다시 고침", updatedAt: Date(timeIntervalSince1970: 300))

        let memos = try await self.sut.list()
        XCTAssertEqual(memos.map(\.book.isbn), [toji.isbn, pachinko.isbn])
    }

    func test_삭제하면_목록에서빠진다() async throws {
        try await self.sut.save(pachinko, text: "좋았다", updatedAt: Date())

        try await self.sut.remove(isbn: pachinko.isbn)

        let memos = try await self.sut.list()
        XCTAssertEqual(memos, [])
    }

    func test_없는메모를삭제해도_실패하지않는다() async throws {
        try await self.sut.remove(isbn: "없는isbn")
    }

    func test_한책만삭제하면_다른책의메모는남는다() async throws {
        try await self.sut.save(pachinko, text: "파친코 메모", updatedAt: Date())
        try await self.sut.save(toji, text: "토지 메모", updatedAt: Date())

        try await self.sut.remove(isbn: pachinko.isbn)

        let memos = try await self.sut.list()
        XCTAssertEqual(memos.map(\.book.isbn), [toji.isbn])
    }

    func test_여러책을동시에저장해도_모두저장된다() async throws {
        await withTaskGroup(of: Void.self) { group in
            for index in 0 ..< 20 {
                group.addTask { [sut] in
                    let book = Book(isbn: "\(index)", title: "책\(index)")
                    try? await sut?.save(book, text: "메모\(index)", updatedAt: Date())
                }
            }
        }

        let memos = try await self.sut.list()
        XCTAssertEqual(memos.count, 20)
    }
}
