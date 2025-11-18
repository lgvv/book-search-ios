import XCTest

import BookDetailFeatureInterface
import BookModel

@testable import BookDetailFeature

final class BookDetailReducerTests: XCTestCase {

    private let sut = BookDetailReducer()
    private let book = Book(isbn: "1", title: "파친코", author: "이민진")

    func test_화면이뜨면_즐겨찾기와메모를관찰하고열람을기록한다() {
        var state = BookDetailReducer.State(book: self.book)

        let effects = self.sut.reduce(into: &state, action: .view(.viewDidLoad))

        XCTAssertEqual(effects, [
            .observeFavorites(isbn: "1"),
            .observeMemo(isbn: "1"),
            .recordViewed(self.book),
        ])
    }

    func test_열람기록은_상세를연순간에일어난다() {
        var state = BookDetailReducer.State(book: self.book)

        let onLoad = self.sut.reduce(into: &state, action: .view(.viewDidLoad))
        let onToggle = self.sut.reduce(into: &state, action: .view(.toggleFavorite))
        let onEdit = self.sut.reduce(into: &state, action: .view(.editMemo))

        XCTAssertTrue(onLoad.contains(.recordViewed(self.book)))
        XCTAssertFalse(onToggle.contains(.recordViewed(self.book)))
        XCTAssertFalse(onEdit.contains(.recordViewed(self.book)))
    }

    func test_하트를누르면_상태를먼저뒤집고쓰기를낸다() {
        var state = BookDetailReducer.State(book: self.book)

        let effects = self.sut.reduce(into: &state, action: .view(.toggleFavorite))

        XCTAssertTrue(state.isFavorite)
        XCTAssertEqual(effects, [.setFavorite(self.book, to: true)])
    }

    func test_이미즐겨찾기면_해제로낸다() {
        var state = BookDetailReducer.State(book: self.book, isFavorite: true)

        let effects = self.sut.reduce(into: &state, action: .view(.toggleFavorite))

        XCTAssertFalse(state.isFavorite)
        XCTAssertEqual(effects, [.setFavorite(self.book, to: false)])
    }

    func test_즐겨찾기스트림이바뀌면_그값으로맞춘다() {
        var state = BookDetailReducer.State(book: self.book, isFavorite: true)

        _ = self.sut.reduce(into: &state, action: .feedback(.favoritesChanged(isFavorite: false)))

        XCTAssertFalse(state.isFavorite)
    }

    func test_메모스트림이바뀌면_본문을담는다() {
        var state = BookDetailReducer.State(book: self.book)

        _ = self.sut.reduce(into: &state, action: .feedback(.memoChanged(text: "좋았다")))

        XCTAssertEqual(state.memoText, "좋았다")
    }

    func test_메모가지워지면_빈문자열이된다() {
        var state = BookDetailReducer.State(book: self.book, memoText: "좋았다")

        _ = self.sut.reduce(into: &state, action: .feedback(.memoChanged(text: "")))

        XCTAssertEqual(state.memoText, "")
    }

    func test_메모편집을누르면_편집화면을요청한다() {
        var state = BookDetailReducer.State(book: self.book)

        let effects = self.sut.reduce(into: &state, action: .view(.editMemo))

        XCTAssertEqual(effects, [.delegate(.didRequestMemoEdit(self.book))])
    }

    func test_처음에는_즐겨찾기가아니고메모가비어있다() {
        let state = BookDetailReducer.State(book: self.book)

        XCTAssertFalse(state.isFavorite)
        XCTAssertEqual(state.memoText, "")
    }
}
