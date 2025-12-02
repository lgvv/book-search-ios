import Foundation
import Testing

import BookModel
import MemoCore
import MemoModel
import Persistence
import PersistenceInterface

@testable import MemoData

struct DefaultMemoRepositoryTests {

    private let pachinko = Book(isbn: "1", title: "파친코", author: "이민진")
    private let toji = Book(isbn: "2", title: "토지", author: "박경리")

    private var sut: (any MemoRepository)!

    init() {
        self.sut = makeMemoRepository(storeFactory: .inMemory)
    }

    @Test
    func 저장한메모를_목록에서읽을수있다() async throws {
        let updatedAt = Date()

        try await self.sut.save(pachinko, text: "좋았다", updatedAt: updatedAt)

        let memos = try await self.sut.list()
        #expect(memos.count == 1)
        #expect(memos.first?.text == "좋았다")
        #expect(memos.first?.book.isbn == pachinko.isbn)
    }

    @Test
    func 책정보를_함께보관한다() async throws {
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
        #expect(memos.first?.book == book)
    }

    @Test
    func 저장한메모가없으면_빈목록이다() async throws {
        let memos = try await self.sut.list()

        #expect(memos == [])
    }

    @Test
    func 같은책에다시저장하면_새항목을만들지않고내용을바꾼다() async throws {
        try await self.sut.save(pachinko, text: "처음", updatedAt: Date(timeIntervalSince1970: 100))

        try await self.sut.save(pachinko, text: "고침", updatedAt: Date(timeIntervalSince1970: 200))

        let memos = try await self.sut.list()
        #expect(memos.count == 1)
        #expect(memos.first?.text == "고침")
    }

    @Test
    func 같은책에다시저장하면_updatedAt도갱신된다() async throws {
        try await self.sut.save(pachinko, text: "처음", updatedAt: Date(timeIntervalSince1970: 100))
        let later = Date(timeIntervalSince1970: 200)

        try await self.sut.save(pachinko, text: "고침", updatedAt: later)

        let memos = try await self.sut.list()
        #expect(memos.first?.updatedAt == later)
    }

    @Test
    func 목록은_최근수정순으로내려온다() async throws {
        try await self.sut.save(toji, text: "먼저", updatedAt: Date(timeIntervalSince1970: 100))
        try await self.sut.save(pachinko, text: "나중", updatedAt: Date(timeIntervalSince1970: 200))

        let memos = try await self.sut.list()

        #expect(memos.map(\.book.isbn) == [pachinko.isbn, toji.isbn])
    }

    @Test
    func 오래된메모를수정하면_목록맨앞으로올라온다() async throws {
        try await self.sut.save(toji, text: "먼저", updatedAt: Date(timeIntervalSince1970: 100))
        try await self.sut.save(pachinko, text: "나중", updatedAt: Date(timeIntervalSince1970: 200))

        try await self.sut.save(toji, text: "다시 고침", updatedAt: Date(timeIntervalSince1970: 300))

        let memos = try await self.sut.list()
        #expect(memos.map(\.book.isbn) == [toji.isbn, pachinko.isbn])
    }

    @Test
    func 삭제하면_목록에서빠진다() async throws {
        try await self.sut.save(pachinko, text: "좋았다", updatedAt: Date())

        try await self.sut.remove(isbn: pachinko.isbn)

        let memos = try await self.sut.list()
        #expect(memos == [])
    }

    @Test
    func 없는메모를삭제해도_실패하지않는다() async throws {
        try await self.sut.remove(isbn: "없는isbn")
    }

    @Test
    func 한책만삭제하면_다른책의메모는남는다() async throws {
        try await self.sut.save(pachinko, text: "파친코 메모", updatedAt: Date())
        try await self.sut.save(toji, text: "토지 메모", updatedAt: Date())

        try await self.sut.remove(isbn: pachinko.isbn)

        let memos = try await self.sut.list()
        #expect(memos.map(\.book.isbn) == [toji.isbn])
    }

    @Test
    func 여러책을동시에저장해도_모두저장된다() async throws {
        await withTaskGroup(of: Void.self) { group in
            for index in 0 ..< 20 {
                group.addTask { [sut] in
                    let book = Book(isbn: "\(index)", title: "책\(index)")
                    try? await sut?.save(book, text: "메모\(index)", updatedAt: Date())
                }
            }
        }

        let memos = try await self.sut.list()
        #expect(memos.count == 20)
    }
}
