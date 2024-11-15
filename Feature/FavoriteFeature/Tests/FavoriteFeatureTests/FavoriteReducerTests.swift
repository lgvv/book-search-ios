import XCTest

import BookModel
import FavoriteFeatureInterface
import SharedFoundation

@testable import FavoriteFeature

final class FavoriteReducerTests: XCTestCase {

    private let sut = FavoriteReducer()

    private func makeBook(_ isbn: String) -> Book {
        Book(isbn: isbn, title: "책 \(isbn)")
    }

    func test_화면이뜨면_즐겨찾기와메모를관찰한다() {
        var state = FavoriteReducer.State()

        let effects = self.sut.reduce(into: &state, action: .view(.viewDidLoad))

        XCTAssertEqual(effects, [.observeFavorites, .observeMemos])
    }

    func test_처음상태는_로딩이다() {
        let state = FavoriteReducer.State()

        XCTAssertEqual(state.books, .loading)
    }

    func test_즐겨찾기스트림을받으면_상태를그대로담는다() {
        var state = FavoriteReducer.State()
        let books = [self.makeBook("1"), self.makeBook("2")]

        _ = self.sut.reduce(into: &state, action: .feedback(.favoritesChanged(.loaded(books))))

        XCTAssertEqual(state.books, .loaded(books))
    }

    func test_실패상태도_그대로담는다() {
        var state = FavoriteReducer.State()

        _ = self.sut.reduce(into: &state, action: .feedback(.favoritesChanged(.failed)))

        XCTAssertEqual(state.books, .failed)
    }

    func test_뒤처짐표시도_그대로담는다() {
        var state = FavoriteReducer.State()
        let books = [self.makeBook("1")]

        _ = self.sut.reduce(into: &state, action: .feedback(
            .favoritesChanged(.loaded(books, isStale: true))
        ))

        XCTAssertEqual(state.books.value, books)
        XCTAssertTrue(state.books.isStale)
    }

    func test_메모스트림을받으면_배지대상을담는다() {
        var state = FavoriteReducer.State()

        _ = self.sut.reduce(into: &state, action: .feedback(.memosChanged(["1"])))

        XCTAssertEqual(state.memoISBNs, ["1"])
    }

    func test_재시도를누르면_목록을다시읽는다() {
        var state = FavoriteReducer.State()
        state.books = .failed

        let effects = self.sut.reduce(into: &state, action: .view(.retryLoad))

        XCTAssertEqual(effects, [.reloadFavorites])
    }

    func test_즐겨찾기를해제하면_제거를낸다() {
        var state = FavoriteReducer.State()
        state.books = .loaded([self.makeBook("1")])

        let effects = self.sut.reduce(into: &state, action: .view(.removeFavorite(self.makeBook("1"))))

        XCTAssertEqual(effects, [.removeFavorite(isbn: "1")])
    }

    func test_해제해도_목록을직접건드리지않는다() {
        var state = FavoriteReducer.State()
        let books = [self.makeBook("1"), self.makeBook("2")]
        state.books = .loaded(books)

        _ = self.sut.reduce(into: &state, action: .view(.removeFavorite(self.makeBook("1"))))

        XCTAssertEqual(state.books.value, books)
    }

    func test_책을고르면_상세로넘긴다() {
        var state = FavoriteReducer.State()
        let book = self.makeBook("1")

        let effects = self.sut.reduce(into: &state, action: .view(.selectBook(book)))

        XCTAssertEqual(effects, [.delegate(.didSelectBook(book))])
    }
}
