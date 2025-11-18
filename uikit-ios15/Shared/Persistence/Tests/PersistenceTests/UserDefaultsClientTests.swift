import XCTest

import PersistenceInterface

@testable import Persistence

final class UserDefaultsClientTests: XCTestCase {

    private var suiteName: String!
    private var sut: UserDefaultsClient!

    private enum Keys {
        static let text = StorageKey<String>(namespace: "test", name: "text")
        static let flag = StorageKey<Bool>(namespace: "test", name: "flag")
        static let count = StorageKey<Int>(namespace: "test", name: "count")
        static let terms = StorageKey<[String]>(namespace: "test", name: "terms")
    }

    override func setUp() {
        super.setUp()
        self.suiteName = "book-search-tests-\(UUID().uuidString)"
        self.sut = .live(suiteName: self.suiteName)
    }

    override func tearDown() {
        UserDefaults().removePersistentDomain(forName: self.suiteName)
        self.sut = nil
        super.tearDown()
    }

    func test_문자열을저장하면_같은키로읽을수있다() {
        self.sut.setString("민음사", for: Keys.text)

        XCTAssertEqual(self.sut.string(Keys.text), "민음사")
    }

    func test_정수와참거짓도_왕복한다() {
        self.sut.setInt(42, for: Keys.count)
        self.sut.setBool(true, for: Keys.flag)

        XCTAssertEqual(self.sut.int(Keys.count), 42)
        XCTAssertEqual(self.sut.bool(Keys.flag), true)
    }

    func test_저장한적없는키는_nil이다() {
        XCTAssertNil(self.sut.string(Keys.text))
        XCTAssertNil(self.sut.bool(Keys.flag))
        XCTAssertNil(self.sut.int(Keys.count))
    }

    func test_false를저장하면_nil이아니라false를돌려준다() {
        self.sut.setBool(false, for: Keys.flag)

        XCTAssertEqual(self.sut.bool(Keys.flag), false)
    }

    func test_Codable값을저장하면_같은값으로복원한다() {
        let terms = ["민음사", "파친코", "토지"]

        self.sut.setObject(terms, for: Keys.terms)

        XCTAssertEqual(self.sut.object(Keys.terms), terms)
    }

    func test_Codable값의순서는_저장한그대로유지된다() {
        let terms = ["세번째", "두번째", "첫번째"]

        self.sut.setObject(terms, for: Keys.terms)

        XCTAssertEqual(self.sut.object(Keys.terms), terms)
    }

    func test_제거하면_다시nil이된다() {
        self.sut.setString("민음사", for: Keys.text)

        self.sut.remove(Keys.text)

        XCTAssertNil(self.sut.string(Keys.text))
    }

    func test_없는키를제거해도_실패하지않는다() {
        self.sut.remove(Keys.text)

        XCTAssertNil(self.sut.string(Keys.text))
    }

    func test_다른suite의클라이언트는_서로의값을보지못한다() {
        let otherSuite = "book-search-tests-\(UUID().uuidString)"
        let other = UserDefaultsClient.live(suiteName: otherSuite)
        defer { UserDefaults().removePersistentDomain(forName: otherSuite) }

        self.sut.setString("이쪽", for: Keys.text)

        XCTAssertEqual(self.sut.string(Keys.text), "이쪽")
        XCTAssertNil(other.string(Keys.text))
    }

    func test_같은suite의클라이언트를새로만들어도_저장한값이보인다() {
        self.sut.setString("영속", for: Keys.text)

        let reopened = UserDefaultsClient.live(suiteName: self.suiteName)

        XCTAssertEqual(reopened.string(Keys.text), "영속")
    }
}

final class StorageKeyTests: XCTestCase {

    func test_키는_네임스페이스와이름을점으로잇는다() {
        let key = StorageKey<String>(namespace: "recentSearch", name: "terms")

        XCTAssertEqual(key.rawValue, "recentSearch.terms")
    }

    func test_네임스페이스가다르면_이름이같아도다른키다() {
        let a = StorageKey<String>(namespace: "search", name: "terms")
        let b = StorageKey<String>(namespace: "config", name: "terms")

        XCTAssertNotEqual(a.rawValue, b.rawValue)
    }
}
