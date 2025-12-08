import Foundation
import Testing

import BookDetailFeatureInterface
import BookModel

@testable import BookDetailFeature

struct BookDetailReducerTests {

    private let sut = BookDetailReducer()
    private let book = Book(isbn: "1", title: "파친코", author: "이민진")

    @Test
    func 화면이뜨면_즐겨찾기와메모를관찰하고열람을기록한다() {
        var state = BookDetailReducer.State(book: self.book)

        let effects = self.sut.reduce(into: &state, action: .view(.start))

        #expect(effects == [
            .observeFavorites(isbn: "1"),
            .observeMemo(isbn: "1"),
            .recordViewed(self.book),
        ])
    }

    @Test
    func 열람기록은_상세를연순간에일어난다() {
        var state = BookDetailReducer.State(book: self.book)

        let onLoad = self.sut.reduce(into: &state, action: .view(.start))
        let onToggle = self.sut.reduce(into: &state, action: .view(.toggleFavorite))
        let onEdit = self.sut.reduce(into: &state, action: .view(.editMemo))

        #expect(onLoad.contains(.recordViewed(self.book)))
        #expect(!(onToggle.contains(.recordViewed(self.book))))
        #expect(!(onEdit.contains(.recordViewed(self.book))))
    }

    @Test
    func 하트를누르면_상태를먼저뒤집고쓰기를낸다() {
        var state = BookDetailReducer.State(book: self.book)

        let effects = self.sut.reduce(into: &state, action: .view(.toggleFavorite))

        #expect(state.isFavorite)
        #expect(effects == [.setFavorite(self.book, to: true)])
    }

    @Test
    func 이미즐겨찾기면_해제로낸다() {
        var state = BookDetailReducer.State(book: self.book, isFavorite: true)

        let effects = self.sut.reduce(into: &state, action: .view(.toggleFavorite))

        #expect(!(state.isFavorite))
        #expect(effects == [.setFavorite(self.book, to: false)])
    }

    @Test
    func 즐겨찾기스트림이바뀌면_그값으로맞춘다() {
        var state = BookDetailReducer.State(book: self.book, isFavorite: true)

        _ = self.sut.reduce(into: &state, action: .feedback(.favoritesChanged(isFavorite: false)))

        #expect(!(state.isFavorite))
    }

    @Test
    func 메모스트림이바뀌면_본문을담는다() {
        var state = BookDetailReducer.State(book: self.book)

        _ = self.sut.reduce(into: &state, action: .feedback(.memoChanged(text: "좋았다")))

        #expect(state.memoText == "좋았다")
    }

    @Test
    func 메모가지워지면_빈문자열이된다() {
        var state = BookDetailReducer.State(book: self.book, memoText: "좋았다")

        _ = self.sut.reduce(into: &state, action: .feedback(.memoChanged(text: "")))

        #expect(state.memoText == "")
    }

    @Test
    func 메모편집을누르면_편집화면을요청한다() {
        var state = BookDetailReducer.State(book: self.book)

        let effects = self.sut.reduce(into: &state, action: .view(.editMemo))

        #expect(effects == [.delegate(.didRequestMemoEdit(self.book))])
    }

    @Test
    func 처음에는_즐겨찾기가아니고메모가비어있다() {
        let state = BookDetailReducer.State(book: self.book)

        #expect(!(state.isFavorite))
        #expect(state.memoText == "")
    }
}
