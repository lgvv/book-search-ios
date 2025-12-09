import Foundation
import Testing

import BookModel
import MemoFeatureInterface

@testable import MemoFeature

struct MemoEditReducerTests {

    private let sut = MemoEditReducer()
    private let book = Book(isbn: "1", title: "파친코")

    private func makeLoadedState(savedText: String = "기존 메모") -> MemoEditReducer.State {
        var state = MemoEditReducer.State(book: self.book)
        state.savedText = savedText
        state.isLoaded = true
        return state
    }

    @Test
    func 화면이뜨면_메모를읽는다() {
        var state = MemoEditReducer.State(book: self.book)

        let effects = self.sut.reduce(into: &state, action: .view(.start))

        #expect(effects == [.loadMemo(isbn: "1")])
    }

    @Test
    func 메모를읽으면_내용을담고로드완료로바꾼다() {
        var state = MemoEditReducer.State(book: self.book)

        _ = self.sut.reduce(into: &state, action: .feedback(.memoLoaded(text: "좋았다")))

        #expect(state.savedText == "좋았다")
        #expect(state.isLoaded)
        #expect(!(state.hasLoadFailure))
    }

    @Test
    func 읽기가실패하면_실패를표시한다() {
        var state = MemoEditReducer.State(book: self.book)

        _ = self.sut.reduce(into: &state, action: .feedback(.didFailToLoad))

        #expect(state.hasLoadFailure)
        #expect(!(state.isLoaded))
    }

    @Test
    func 재시도를누르면_실패표시를지우고다시읽는다() {
        var state = MemoEditReducer.State(book: self.book)
        _ = self.sut.reduce(into: &state, action: .feedback(.didFailToLoad))

        let effects = self.sut.reduce(into: &state, action: .view(.retryLoad))

        #expect(effects == [.loadMemo(isbn: "1")])
        #expect(!(state.hasLoadFailure))
    }

    @Test
    func 이미로드됐으면_재시도가아무것도하지않는다() {
        var state = self.makeLoadedState()

        let effects = self.sut.reduce(into: &state, action: .view(.retryLoad))

        #expect(effects == [])
    }

    @Test
    func 실패알림을닫으면_표시가사라진다() {
        var state = MemoEditReducer.State(book: self.book)
        _ = self.sut.reduce(into: &state, action: .feedback(.didFailToLoad))

        _ = self.sut.reduce(into: &state, action: .view(.didDismissLoadFailure))

        #expect(!(state.hasLoadFailure))
    }

    @Test
    func 로드된뒤저장하면_저장을낸다() {
        var state = self.makeLoadedState()

        let effects = self.sut.reduce(into: &state, action: .view(.save("고친 메모")))

        #expect(effects == [.saveMemo(self.book, text: "고친 메모")])
        #expect(state.isSaving)
    }

    @Test
    func 로드전에저장하면_아무것도하지않는다() {
        var state = MemoEditReducer.State(book: self.book)

        let effects = self.sut.reduce(into: &state, action: .view(.save("새 메모")))

        #expect(effects == [])
        #expect(!(state.isSaving))
    }

    @Test
    func 저장중에다시저장하면_중복으로내지않는다() {
        var state = self.makeLoadedState()
        _ = self.sut.reduce(into: &state, action: .view(.save("첫번째")))

        let effects = self.sut.reduce(into: &state, action: .view(.save("두번째")))

        #expect(effects == [])
    }

    @Test
    func 저장이성공하면_화면을닫는다() {
        var state = self.makeLoadedState()
        _ = self.sut.reduce(into: &state, action: .view(.save("고친 메모")))

        let effects = self.sut.reduce(into: &state, action: .feedback(.didSave))

        #expect(effects == [.delegate(.didFinish)])
    }

    @Test
    func 저장이실패하면_저장중표시를풀고실패를알린다() {
        var state = self.makeLoadedState()
        _ = self.sut.reduce(into: &state, action: .view(.save("고친 메모")))

        _ = self.sut.reduce(into: &state, action: .feedback(.didFailToSave))

        #expect(!(state.isSaving))
        #expect(state.hasSaveFailure)
    }

    @Test
    func 저장에실패한뒤_다시저장할수있다() {
        var state = self.makeLoadedState()
        _ = self.sut.reduce(into: &state, action: .view(.save("고친 메모")))
        _ = self.sut.reduce(into: &state, action: .feedback(.didFailToSave))

        let effects = self.sut.reduce(into: &state, action: .view(.save("다시 시도")))

        #expect(effects == [.saveMemo(self.book, text: "다시 시도")])
    }

    @Test
    func 저장실패알림을닫으면_표시가사라진다() {
        var state = self.makeLoadedState()
        _ = self.sut.reduce(into: &state, action: .view(.save("고친 메모")))
        _ = self.sut.reduce(into: &state, action: .feedback(.didFailToSave))

        _ = self.sut.reduce(into: &state, action: .view(.didDismissSaveFailure))

        #expect(!(state.hasSaveFailure))
    }

    @Test
    func 저장된메모가없으면_신규로본다() {
        let state = MemoEditReducer.State(book: self.book)

        #expect(state.isNew)
    }

    @Test
    func 저장된메모가있으면_신규가아니다() {
        let state = self.makeLoadedState(savedText: "기존 메모")

        #expect(!(state.isNew))
    }

    @Test
    func 빈메모를읽어오면_여전히신규다() {
        var state = MemoEditReducer.State(book: self.book)

        _ = self.sut.reduce(into: &state, action: .feedback(.memoLoaded(text: "")))

        #expect(state.isNew)
        #expect(state.isLoaded)
    }
}
