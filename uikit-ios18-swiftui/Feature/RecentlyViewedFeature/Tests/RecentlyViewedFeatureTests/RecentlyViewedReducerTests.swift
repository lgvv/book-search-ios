import Foundation
import Testing

import BookModel
import RecentlyViewedFeatureInterface
import RecentlyViewedModel
import SharedFoundation

@testable import RecentlyViewedFeature

struct RecentlyViewedReducerTests {

    private let sut = RecentlyViewedReducer()

    private func makeBook(_ isbn: String) -> Book {
        Book(isbn: isbn, title: "책 \(isbn)")
    }

    private func makeViewed(_ isbn: String) -> ViewedBook {
        ViewedBook(book: self.makeBook(isbn), viewedAt: Date(timeIntervalSince1970: 0))
    }

    @Test
    func 화면이뜨면_목록과즐겨찾기와메모를관찰한다() {
        var state = RecentlyViewedReducer.State()

        let effects = self.sut.reduce(into: &state, action: .view(.start))

        #expect(effects == [.observeItems, .observeFavorites, .observeMemos])
    }

    @Test
    func 처음상태는_로딩이다() {
        let state = RecentlyViewedReducer.State()

        #expect(state.items == .loading)
    }

    @Test
    func 목록스트림을받으면_상태를그대로담는다() {
        var state = RecentlyViewedReducer.State()
        let items = [self.makeViewed("1"), self.makeViewed("2")]

        _ = self.sut.reduce(into: &state, action: .feedback(.itemsChanged(.loaded(items))))

        #expect(state.items == .loaded(items))
    }

    @Test
    func 실패와뒤처짐도_그대로담는다() {
        var state = RecentlyViewedReducer.State()
        let items = [self.makeViewed("1")]

        _ = self.sut.reduce(into: &state, action: .feedback(.itemsChanged(.failed)))
        let afterFailure = state.items
        _ = self.sut.reduce(into: &state, action: .feedback(
            .itemsChanged(.loaded(items, isStale: true))
        ))

        #expect(afterFailure == .failed)
        #expect(state.items.isStale)
    }

    @Test
    func 즐겨찾기와메모스트림을받으면_배지대상을담는다() {
        var state = RecentlyViewedReducer.State()

        _ = self.sut.reduce(into: &state, action: .feedback(.favoritesChanged(["1"])))
        _ = self.sut.reduce(into: &state, action: .feedback(.memosChanged(["2"])))

        #expect(state.favoriteISBNs == ["1"])
        #expect(state.memoISBNs == ["2"])
    }

    @Test
    func 목록이비어있으면_전체지우기를내보내지않는다() {
        var state = RecentlyViewedReducer.State()

        _ = self.sut.reduce(into: &state, action: .feedback(.itemsChanged(.loaded([]))))

        #expect(!(state.canClear))
    }

    @Test
    func 로딩중에도_전체지우기를내보내지않는다() {
        let state = RecentlyViewedReducer.State()

        #expect(!(state.canClear))
    }

    @Test
    func 항목이있으면_전체지우기를내보낸다() {
        var state = RecentlyViewedReducer.State()

        _ = self.sut.reduce(into: &state, action: .feedback(
            .itemsChanged(.loaded([self.makeViewed("1")]))
        ))

        #expect(state.canClear)
    }

    @Test
    func 재시도를누르면_목록을다시읽는다() {
        var state = RecentlyViewedReducer.State()
        state.items = .failed

        let effects = self.sut.reduce(into: &state, action: .view(.retryLoad))

        #expect(effects == [.reloadItems])
    }

    @Test
    func 항목을스와이프로지우면_삭제를낸다() {
        var state = RecentlyViewedReducer.State()
        state.items = .loaded([self.makeViewed("1")])

        let effects = self.sut.reduce(into: &state, action: .view(.removeItem(isbn: "1")))

        #expect(effects == [.removeItem(isbn: "1")])
    }

    @Test
    func 삭제해도_목록을직접건드리지않는다() {
        var state = RecentlyViewedReducer.State()
        let items = [self.makeViewed("1"), self.makeViewed("2")]
        state.items = .loaded(items)

        _ = self.sut.reduce(into: &state, action: .view(.removeItem(isbn: "1")))

        #expect(state.items.value == items)
    }

    @Test
    func 전체지우기를확인하면_전체삭제를낸다() {
        var state = RecentlyViewedReducer.State()
        state.items = .loaded([self.makeViewed("1")])

        let effects = self.sut.reduce(into: &state, action: .view(.confirmClearAll))

        #expect(effects == [.clearAll])
    }

    @Test
    func 책을고르면_상세로넘긴다() {
        var state = RecentlyViewedReducer.State()
        let book = self.makeBook("1")

        let effects = self.sut.reduce(into: &state, action: .view(.selectBook(book)))

        #expect(effects == [.delegate(.didSelectBook(book))])
    }
}
