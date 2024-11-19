import XCTest

import BookModel
import MemoFeatureInterface
import MemoModel
import SharedFoundation

@testable import MemoFeature

final class MemoReducerTests: XCTestCase {

    private let sut = MemoReducer()

    private func makeBook(_ isbn: String) -> Book {
        Book(isbn: isbn, title: "책 \(isbn)")
    }

    private func makeMemo(_ isbn: String, text: String = "좋았다") -> BookMemo {
        BookMemo(book: self.makeBook(isbn), text: text, updatedAt: Date(timeIntervalSince1970: 0))
    }

    func test_화면이뜨면_메모와즐겨찾기를관찰한다() {
        var state = MemoReducer.State()

        let effects = self.sut.reduce(into: &state, action: .view(.viewDidLoad))

        XCTAssertEqual(effects, [.observeMemos, .observeFavorites])
    }

    func test_처음상태는_로딩이다() {
        let state = MemoReducer.State()

        XCTAssertEqual(state.memos, .loading)
    }

    func test_메모스트림을받으면_상태를그대로담는다() {
        var state = MemoReducer.State()
        let memos = [self.makeMemo("1")]

        _ = self.sut.reduce(into: &state, action: .feedback(.memosChanged(.loaded(memos))))

        XCTAssertEqual(state.memos, .loaded(memos))
    }

    func test_실패와뒤처짐도_그대로담는다() {
        var state = MemoReducer.State()
        let memos = [self.makeMemo("1")]

        _ = self.sut.reduce(into: &state, action: .feedback(.memosChanged(.failed)))
        let afterFailure = state.memos
        _ = self.sut.reduce(into: &state, action: .feedback(
            .memosChanged(.loaded(memos, isStale: true))
        ))

        XCTAssertEqual(afterFailure, .failed)
        XCTAssertTrue(state.memos.isStale)
        XCTAssertEqual(state.memos.value, memos)
    }

    func test_즐겨찾기스트림을받으면_하트대상을담는다() {
        var state = MemoReducer.State()

        _ = self.sut.reduce(into: &state, action: .feedback(.favoritesChanged(["1"])))

        XCTAssertEqual(state.favoriteISBNs, ["1"])
    }

    func test_재시도를누르면_메모를다시읽는다() {
        var state = MemoReducer.State()
        state.memos = .failed

        let effects = self.sut.reduce(into: &state, action: .view(.retryLoad))

        XCTAssertEqual(effects, [.reloadMemos])
    }

    func test_하트를누르면_상태를먼저뒤집고쓰기를낸다() {
        var state = MemoReducer.State()
        let book = self.makeBook("1")

        let effects = self.sut.reduce(into: &state, action: .view(.toggleFavorite(book)))

        XCTAssertTrue(state.favoriteISBNs.contains("1"))
        XCTAssertEqual(effects, [.setFavorite(book, to: true)])
    }

    func test_이미즐겨찾기인책의하트를누르면_해제로낸다() {
        var state = MemoReducer.State()
        state.favoriteISBNs = ["1"]
        let book = self.makeBook("1")

        let effects = self.sut.reduce(into: &state, action: .view(.toggleFavorite(book)))

        XCTAssertFalse(state.favoriteISBNs.contains("1"))
        XCTAssertEqual(effects, [.setFavorite(book, to: false)])
    }

    func test_책을고르면_상세로넘긴다() {
        var state = MemoReducer.State()
        let book = self.makeBook("1")

        let effects = self.sut.reduce(into: &state, action: .view(.selectBook(book)))

        XCTAssertEqual(effects, [.delegate(.didSelectBook(book))])
    }
}
