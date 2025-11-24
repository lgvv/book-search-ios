import Foundation
import Testing

import BookModel
import FavoriteFeatureInterface
import SharedFoundation

@testable import FavoriteFeature

struct FavoriteReducerTests {

    private let sut = FavoriteReducer()

    private func makeBook(_ isbn: String) -> Book {
        Book(isbn: isbn, title: "책 \(isbn)")
    }

    @Test
    func 화면이뜨면_즐겨찾기와메모를관찰한다() {
        var state = FavoriteReducer.State()

        let effects = self.sut.reduce(into: &state, action: .view(.viewDidLoad))

        #expect(effects == [.observeFavorites, .observeMemos])
    }

    @Test
    func 처음상태는_로딩이다() {
        let state = FavoriteReducer.State()

        #expect(state.books == .loading)
    }

    @Test
    func 즐겨찾기스트림을받으면_상태를그대로담는다() {
        var state = FavoriteReducer.State()
        let books = [self.makeBook("1"), self.makeBook("2")]

        _ = self.sut.reduce(into: &state, action: .feedback(.favoritesChanged(.loaded(books))))

        #expect(state.books == .loaded(books))
    }

    @Test
    func 실패상태도_그대로담는다() {
        var state = FavoriteReducer.State()

        _ = self.sut.reduce(into: &state, action: .feedback(.favoritesChanged(.failed)))

        #expect(state.books == .failed)
    }

    @Test
    func 뒤처짐표시도_그대로담는다() {
        var state = FavoriteReducer.State()
        let books = [self.makeBook("1")]

        _ = self.sut.reduce(into: &state, action: .feedback(
            .favoritesChanged(.loaded(books, isStale: true))
        ))

        #expect(state.books.value == books)
        #expect(state.books.isStale)
    }

    @Test
    func 메모스트림을받으면_배지대상을담는다() {
        var state = FavoriteReducer.State()

        _ = self.sut.reduce(into: &state, action: .feedback(.memosChanged(["1"])))

        #expect(state.memoISBNs == ["1"])
    }

    @Test
    func 재시도를누르면_목록을다시읽는다() {
        var state = FavoriteReducer.State()
        state.books = .failed

        let effects = self.sut.reduce(into: &state, action: .view(.retryLoad))

        #expect(effects == [.reloadFavorites])
    }

    @Test
    func 즐겨찾기를해제하면_제거를낸다() {
        var state = FavoriteReducer.State()
        state.books = .loaded([self.makeBook("1")])

        let effects = self.sut.reduce(into: &state, action: .view(.removeFavorite(self.makeBook("1"))))

        #expect(effects == [.removeFavorite(isbn: "1")])
    }

    @Test
    func 해제해도_목록을직접건드리지않는다() {
        var state = FavoriteReducer.State()
        let books = [self.makeBook("1"), self.makeBook("2")]
        state.books = .loaded(books)

        _ = self.sut.reduce(into: &state, action: .view(.removeFavorite(self.makeBook("1"))))

        #expect(state.books.value == books)
    }

    @Test
    func 책을고르면_상세로넘긴다() {
        var state = FavoriteReducer.State()
        let book = self.makeBook("1")

        let effects = self.sut.reduce(into: &state, action: .view(.selectBook(book)))

        #expect(effects == [.delegate(.didSelectBook(book))])
    }
}
