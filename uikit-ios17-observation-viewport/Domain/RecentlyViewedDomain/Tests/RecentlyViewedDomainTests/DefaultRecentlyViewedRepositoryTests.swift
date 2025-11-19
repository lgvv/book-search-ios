import XCTest

import BookModel
import Persistence
import PersistenceInterface
import RecentlyViewedCore
import RecentlyViewedModel

@testable import RecentlyViewedData

final class DefaultRecentlyViewedRepositoryTests: XCTestCase {

    private let pachinko = Book(isbn: "1", title: "파친코", author: "이민진")
    private let toji = Book(isbn: "2", title: "토지", author: "박경리")
    private let humanActs = Book(isbn: "3", title: "소년이 온다", author: "한강")

    private var sut: (any RecentlyViewedRepository)!

    override func setUp() {
        super.setUp()
        self.sut = makeRecentlyViewedRepository(storeFactory: .inMemory)
    }

    func test_책을기록하면_목록에서읽을수있다() async throws {
        try await self.sut.record(book: pachinko, keeping: 20)

        let items = try await self.sut.list()
        XCTAssertEqual(items.map(\.book.isbn), [pachinko.isbn])
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

        try await self.sut.record(book: book, keeping: 20)

        let items = try await self.sut.list()
        XCTAssertEqual(items.first?.book, book)
    }

    func test_기록한적없으면_빈목록이다() async throws {
        let items = try await self.sut.list()

        XCTAssertEqual(items, [])
    }

    func test_최근에본책이_목록맨위에온다() async throws {
        try await self.sut.record(book: pachinko, keeping: 20)
        try await self.sut.record(book: toji, keeping: 20)
        try await self.sut.record(book: humanActs, keeping: 20)

        let items = try await self.sut.list()
        XCTAssertEqual(items.map(\.book.isbn), [humanActs.isbn, toji.isbn, pachinko.isbn])
    }

    func test_같은책을다시보면_중복항목이생기지않는다() async throws {
        try await self.sut.record(book: pachinko, keeping: 20)

        try await self.sut.record(book: pachinko, keeping: 20)

        let items = try await self.sut.list()
        XCTAssertEqual(items.count, 1)
    }

    func test_같은책을다시보면_맨위로올라온다() async throws {
        try await self.sut.record(book: pachinko, keeping: 20)
        try await self.sut.record(book: toji, keeping: 20)

        try await self.sut.record(book: pachinko, keeping: 20)

        let items = try await self.sut.list()
        XCTAssertEqual(items.map(\.book.isbn), [pachinko.isbn, toji.isbn])
    }

    func test_같은책을다시보면_본시각이갱신된다() async throws {
        try await self.sut.record(book: pachinko, keeping: 20)
        let firstList = try await self.sut.list()
        let firstViewedAt = try XCTUnwrap(firstList.first?.viewedAt)

        try await self.sut.record(book: pachinko, keeping: 20)

        let laterList = try await self.sut.list()
        let laterViewedAt = try XCTUnwrap(laterList.first?.viewedAt)
        XCTAssertGreaterThan(laterViewedAt, firstViewedAt)
    }

    func test_같은책을다시보면_바뀐책정보로갱신된다() async throws {
        try await self.sut.record(book: Book(isbn: "1", title: "옛 제목"), keeping: 20)

        try await self.sut.record(book: Book(isbn: "1", title: "새 제목"), keeping: 20)

        let items = try await self.sut.list()
        XCTAssertEqual(items.first?.book.title, "새 제목")
    }

    func test_상한을넘으면_가장오래본책부터밀려난다() async throws {
        for index in 1 ... 5 {
            try await self.sut.record(book: Book(isbn: "\(index)", title: "책\(index)"), keeping: 3)
        }

        let items = try await self.sut.list()
        XCTAssertEqual(items.map(\.book.isbn), ["5", "4", "3"])
    }

    func test_상한안에서는_아무것도밀려나지않는다() async throws {
        for index in 1 ... 3 {
            try await self.sut.record(book: Book(isbn: "\(index)", title: "책\(index)"), keeping: 20)
        }

        let items = try await self.sut.list()
        XCTAssertEqual(items.count, 3)
    }

    func test_상한초과여부는_재열람으로항목수가늘지않을때는영향이없다() async throws {
        for index in 1 ... 3 {
            try await self.sut.record(book: Book(isbn: "\(index)", title: "책\(index)"), keeping: 3)
        }

        try await self.sut.record(book: Book(isbn: "1", title: "책1"), keeping: 3)

        let items = try await self.sut.list()
        XCTAssertEqual(items.map(\.book.isbn), ["1", "3", "2"])
    }

    func test_한항목을삭제하면_그책만빠진다() async throws {
        try await self.sut.record(book: pachinko, keeping: 20)
        try await self.sut.record(book: toji, keeping: 20)

        try await self.sut.remove(isbn: pachinko.isbn)

        let items = try await self.sut.list()
        XCTAssertEqual(items.map(\.book.isbn), [toji.isbn])
    }

    func test_없는항목을삭제해도_실패하지않는다() async throws {
        try await self.sut.remove(isbn: "없는isbn")
    }

    func test_전체를지우면_목록이비워진다() async throws {
        try await self.sut.record(book: pachinko, keeping: 20)
        try await self.sut.record(book: toji, keeping: 20)

        try await self.sut.clear()

        let items = try await self.sut.list()
        XCTAssertEqual(items, [])
    }

    func test_비어있는목록을지워도_실패하지않는다() async throws {
        try await self.sut.clear()
    }

    func test_전체를지운뒤에도_다시기록할수있다() async throws {
        try await self.sut.record(book: pachinko, keeping: 20)
        try await self.sut.clear()

        try await self.sut.record(book: toji, keeping: 20)

        let items = try await self.sut.list()
        XCTAssertEqual(items.map(\.book.isbn), [toji.isbn])
    }
}
