import XCTest

import BookModel
import RecentlyViewedFeatureInterface
import RecentlyViewedModel
import SharedFoundation

@testable import RecentlyViewedFeature

final class RecentlyViewedReducerTests: XCTestCase {

    private let sut = RecentlyViewedReducer()

    private func makeBook(_ isbn: String) -> Book {
        Book(isbn: isbn, title: "책 \(isbn)")
    }

    private func makeViewed(_ isbn: String) -> ViewedBook {
        ViewedBook(book: self.makeBook(isbn), viewedAt: Date(timeIntervalSince1970: 0))
    }

    func test_화면이뜨면_목록과즐겨찾기와메모를관찰한다() {
        var state = RecentlyViewedReducer.State()

        let effects = self.sut.reduce(into: &state, action: .view(.viewDidLoad))

        XCTAssertEqual(effects, [.observeItems, .observeFavorites, .observeMemos])
    }

    func test_처음상태는_로딩이다() {
        let state = RecentlyViewedReducer.State()

        XCTAssertEqual(state.items, .loading)
    }

    func test_목록스트림을받으면_상태를그대로담는다() {
        var state = RecentlyViewedReducer.State()
        let items = [self.makeViewed("1"), self.makeViewed("2")]

        _ = self.sut.reduce(into: &state, action: .feedback(.itemsChanged(.loaded(items))))

        XCTAssertEqual(state.items, .loaded(items))
    }

    func test_실패와뒤처짐도_그대로담는다() {
        var state = RecentlyViewedReducer.State()
        let items = [self.makeViewed("1")]

        _ = self.sut.reduce(into: &state, action: .feedback(.itemsChanged(.failed)))
        let afterFailure = state.items
        _ = self.sut.reduce(into: &state, action: .feedback(
            .itemsChanged(.loaded(items, isStale: true))
        ))

        XCTAssertEqual(afterFailure, .failed)
        XCTAssertTrue(state.items.isStale)
    }

    func test_즐겨찾기와메모스트림을받으면_배지대상을담는다() {
        var state = RecentlyViewedReducer.State()

        _ = self.sut.reduce(into: &state, action: .feedback(.favoritesChanged(["1"])))
        _ = self.sut.reduce(into: &state, action: .feedback(.memosChanged(["2"])))

        XCTAssertEqual(state.favoriteISBNs, ["1"])
        XCTAssertEqual(state.memoISBNs, ["2"])
    }

    func test_목록이비어있으면_전체지우기를내보내지않는다() {
        var state = RecentlyViewedReducer.State()

        _ = self.sut.reduce(into: &state, action: .feedback(.itemsChanged(.loaded([]))))

        XCTAssertFalse(state.canClear)
    }

    func test_로딩중에도_전체지우기를내보내지않는다() {
        let state = RecentlyViewedReducer.State()

        XCTAssertFalse(state.canClear)
    }

    func test_항목이있으면_전체지우기를내보낸다() {
        var state = RecentlyViewedReducer.State()

        _ = self.sut.reduce(into: &state, action: .feedback(
            .itemsChanged(.loaded([self.makeViewed("1")]))
        ))

        XCTAssertTrue(state.canClear)
    }

    func test_재시도를누르면_목록을다시읽는다() {
        var state = RecentlyViewedReducer.State()
        state.items = .failed

        let effects = self.sut.reduce(into: &state, action: .view(.retryLoad))

        XCTAssertEqual(effects, [.reloadItems])
    }

    func test_항목을스와이프로지우면_삭제를낸다() {
        var state = RecentlyViewedReducer.State()
        state.items = .loaded([self.makeViewed("1")])

        let effects = self.sut.reduce(into: &state, action: .view(.removeItem(isbn: "1")))

        XCTAssertEqual(effects, [.removeItem(isbn: "1")])
    }

    func test_삭제해도_목록을직접건드리지않는다() {
        var state = RecentlyViewedReducer.State()
        let items = [self.makeViewed("1"), self.makeViewed("2")]
        state.items = .loaded(items)

        _ = self.sut.reduce(into: &state, action: .view(.removeItem(isbn: "1")))

        XCTAssertEqual(state.items.value, items)
    }

    func test_전체지우기를확인하면_전체삭제를낸다() {
        var state = RecentlyViewedReducer.State()
        state.items = .loaded([self.makeViewed("1")])

        let effects = self.sut.reduce(into: &state, action: .view(.confirmClearAll))

        XCTAssertEqual(effects, [.clearAll])
    }

    func test_책을고르면_상세로넘긴다() {
        var state = RecentlyViewedReducer.State()
        let book = self.makeBook("1")

        let effects = self.sut.reduce(into: &state, action: .view(.selectBook(book)))

        XCTAssertEqual(effects, [.delegate(.didSelectBook(book))])
    }
}
