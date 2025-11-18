import XCTest

import PersistenceInterface
import RecentSearchCore
import TestSupport

@testable import RecentSearchData

final class DefaultRecentSearchRepositoryTests: XCTestCase {

    private var storage: Locked<[String: Data]>!
    private var sut: (any RecentSearchRepository)!

    override func setUp() {
        super.setUp()
        let storage = Locked<[String: Data]>([:])
        self.storage = storage
        self.sut = makeRecentSearchRepository(
            client: UserDefaultsClient(
                string: { _ in nil },
                bool: { _ in nil },
                int: { _ in nil },
                data: { key in storage.value[key] },
                setString: { _, _ in },
                setBool: { _, _ in },
                setInt: { _, _ in },
                setData: { data, key in storage.withValue { $0[key] = data } },
                remove: { key in storage.withValue { $0[key] = nil } }
            )
        )
    }

    func test_검색어를기록하면_목록에서읽을수있다() async throws {
        try await self.sut.record(term: "민음사", keeping: 10)

        let terms = try await self.sut.list()
        XCTAssertEqual(terms, ["민음사"])
    }

    func test_새검색어는_목록맨앞에놓인다() async throws {
        try await self.sut.record(term: "먼저", keeping: 10)

        try await self.sut.record(term: "나중", keeping: 10)

        let terms = try await self.sut.list()
        XCTAssertEqual(terms, ["나중", "먼저"])
    }

    func test_이미있는검색어를다시기록하면_중복없이맨앞으로올라온다() async throws {
        try await self.sut.record(term: "민음사", keeping: 10)
        try await self.sut.record(term: "파친코", keeping: 10)
        try await self.sut.record(term: "토지", keeping: 10)

        try await self.sut.record(term: "민음사", keeping: 10)

        let terms = try await self.sut.list()
        XCTAssertEqual(terms, ["민음사", "토지", "파친코"])
    }

    func test_상한을넘으면_가장오래된검색어부터밀려난다() async throws {
        for index in 1 ... 5 {
            try await self.sut.record(term: "검색어\(index)", keeping: 3)
        }

        let terms = try await self.sut.list()
        XCTAssertEqual(terms, ["검색어5", "검색어4", "검색어3"])
    }

    func test_상한이1이면_가장최근검색어하나만남는다() async throws {
        try await self.sut.record(term: "먼저", keeping: 1)

        try await self.sut.record(term: "나중", keeping: 1)

        let terms = try await self.sut.list()
        XCTAssertEqual(terms, ["나중"])
    }

    func test_상한이줄어들면_다음기록에서목록이잘린다() async throws {
        for index in 1 ... 5 {
            try await self.sut.record(term: "검색어\(index)", keeping: 10)
        }

        try await self.sut.record(term: "새검색어", keeping: 2)

        let terms = try await self.sut.list()
        XCTAssertEqual(terms, ["새검색어", "검색어5"])
    }

    func test_검색어를제거하면_목록에서빠진다() async throws {
        try await self.sut.record(term: "민음사", keeping: 10)
        try await self.sut.record(term: "파친코", keeping: 10)

        try await self.sut.remove(term: "민음사")

        let terms = try await self.sut.list()
        XCTAssertEqual(terms, ["파친코"])
    }

    func test_없는검색어를제거해도_목록이그대로다() async throws {
        try await self.sut.record(term: "민음사", keeping: 10)

        try await self.sut.remove(term: "없는말")

        let terms = try await self.sut.list()
        XCTAssertEqual(terms, ["민음사"])
    }

    func test_제거해도_나머지순서는유지된다() async throws {
        try await self.sut.record(term: "1", keeping: 10)
        try await self.sut.record(term: "2", keeping: 10)
        try await self.sut.record(term: "3", keeping: 10)

        try await self.sut.remove(term: "2")

        let terms = try await self.sut.list()
        XCTAssertEqual(terms, ["3", "1"])
    }

    func test_기록한적없으면_빈목록이다() async throws {
        let terms = try await self.sut.list()

        XCTAssertEqual(terms, [])
    }

    func test_같은저장소를다시열면_기록이남아있다() async throws {
        try await self.sut.record(term: "민음사", keeping: 10)
        let storage = self.storage!

        let reopened = makeRecentSearchRepository(
            client: UserDefaultsClient(
                string: { _ in nil },
                bool: { _ in nil },
                int: { _ in nil },
                data: { key in storage.value[key] },
                setString: { _, _ in },
                setBool: { _, _ in },
                setInt: { _, _ in },
                setData: { data, key in storage.withValue { $0[key] = data } },
                remove: { key in storage.withValue { $0[key] = nil } }
            )
        )

        let terms = try await reopened.list()
        XCTAssertEqual(terms, ["민음사"])
    }
}
