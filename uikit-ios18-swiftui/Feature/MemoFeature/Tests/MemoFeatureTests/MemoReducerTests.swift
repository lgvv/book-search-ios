import Foundation
import Testing

import BookModel
import MemoFeatureInterface
import MemoModel
import SharedFoundation

@testable import MemoFeature

struct MemoReducerTests {

    private let sut = MemoReducer()

    private func makeBook(_ isbn: String) -> Book {
        Book(isbn: isbn, title: "책 \(isbn)")
    }

    private func makeMemo(_ isbn: String, text: String = "좋았다") -> BookMemo {
        BookMemo(book: self.makeBook(isbn), text: text, updatedAt: Date(timeIntervalSince1970: 0))
    }

    @Test
    func 화면이뜨면_메모와즐겨찾기를관찰한다() {
        var state = MemoReducer.State()

        let effects = self.sut.reduce(into: &state, action: .view(.viewDidLoad))

        #expect(effects == [.observeMemos, .observeFavorites])
    }

    @Test
    func 처음상태는_로딩이다() {
        let state = MemoReducer.State()

        #expect(state.memos == .loading)
    }

    @Test
    func 메모스트림을받으면_상태를그대로담는다() {
        var state = MemoReducer.State()
        let memos = [self.makeMemo("1")]

        _ = self.sut.reduce(into: &state, action: .feedback(.memosChanged(.loaded(memos))))

        #expect(state.memos == .loaded(memos))
    }

    @Test
    func 실패와뒤처짐도_그대로담는다() {
        var state = MemoReducer.State()
        let memos = [self.makeMemo("1")]

        _ = self.sut.reduce(into: &state, action: .feedback(.memosChanged(.failed)))
        let afterFailure = state.memos
        _ = self.sut.reduce(into: &state, action: .feedback(
            .memosChanged(.loaded(memos, isStale: true))
        ))

        #expect(afterFailure == .failed)
        #expect(state.memos.isStale)
        #expect(state.memos.value == memos)
    }

    @Test
    func 즐겨찾기스트림을받으면_하트대상을담는다() {
        var state = MemoReducer.State()

        _ = self.sut.reduce(into: &state, action: .feedback(.favoritesChanged(["1"])))

        #expect(state.favoriteISBNs == ["1"])
    }

    @Test
    func 재시도를누르면_메모를다시읽는다() {
        var state = MemoReducer.State()
        state.memos = .failed

        let effects = self.sut.reduce(into: &state, action: .view(.retryLoad))

        #expect(effects == [.reloadMemos])
    }

    @Test
    func 하트를누르면_상태를먼저뒤집고쓰기를낸다() {
        var state = MemoReducer.State()
        let book = self.makeBook("1")

        let effects = self.sut.reduce(into: &state, action: .view(.toggleFavorite(book)))

        #expect(state.favoriteISBNs.contains("1"))
        #expect(effects == [.setFavorite(book, to: true)])
    }

    @Test
    func 이미즐겨찾기인책의하트를누르면_해제로낸다() {
        var state = MemoReducer.State()
        state.favoriteISBNs = ["1"]
        let book = self.makeBook("1")

        let effects = self.sut.reduce(into: &state, action: .view(.toggleFavorite(book)))

        #expect(!(state.favoriteISBNs.contains("1")))
        #expect(effects == [.setFavorite(book, to: false)])
    }

    @Test
    func 책을고르면_상세로넘긴다() {
        var state = MemoReducer.State()
        let book = self.makeBook("1")

        let effects = self.sut.reduce(into: &state, action: .view(.selectBook(book)))

        #expect(effects == [.delegate(.didSelectBook(book))])
    }
}
