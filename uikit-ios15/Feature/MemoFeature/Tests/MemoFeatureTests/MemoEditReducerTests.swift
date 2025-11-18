import XCTest

import BookModel
import MemoFeatureInterface

@testable import MemoFeature

final class MemoEditReducerTests: XCTestCase {

    private let sut = MemoEditReducer()
    private let book = Book(isbn: "1", title: "파친코")

    private func makeLoadedState(savedText: String = "기존 메모") -> MemoEditReducer.State {
        var state = MemoEditReducer.State(book: self.book)
        state.savedText = savedText
        state.isLoaded = true
        return state
    }

    func test_화면이뜨면_메모를읽는다() {
        var state = MemoEditReducer.State(book: self.book)

        let effects = self.sut.reduce(into: &state, action: .view(.viewDidLoad))

        XCTAssertEqual(effects, [.loadMemo(isbn: "1")])
    }

    func test_메모를읽으면_내용을담고로드완료로바꾼다() {
        var state = MemoEditReducer.State(book: self.book)

        _ = self.sut.reduce(into: &state, action: .feedback(.memoLoaded(text: "좋았다")))

        XCTAssertEqual(state.savedText, "좋았다")
        XCTAssertTrue(state.isLoaded)
        XCTAssertFalse(state.hasLoadFailure)
    }

    func test_읽기가실패하면_실패를표시한다() {
        var state = MemoEditReducer.State(book: self.book)

        _ = self.sut.reduce(into: &state, action: .feedback(.didFailToLoad))

        XCTAssertTrue(state.hasLoadFailure)
        XCTAssertFalse(state.isLoaded)
    }

    func test_재시도를누르면_실패표시를지우고다시읽는다() {
        var state = MemoEditReducer.State(book: self.book)
        _ = self.sut.reduce(into: &state, action: .feedback(.didFailToLoad))

        let effects = self.sut.reduce(into: &state, action: .view(.retryLoad))

        XCTAssertEqual(effects, [.loadMemo(isbn: "1")])
        XCTAssertFalse(state.hasLoadFailure)
    }

    func test_이미로드됐으면_재시도가아무것도하지않는다() {
        var state = self.makeLoadedState()

        let effects = self.sut.reduce(into: &state, action: .view(.retryLoad))

        XCTAssertEqual(effects, [])
    }

    func test_실패알림을닫으면_표시가사라진다() {
        var state = MemoEditReducer.State(book: self.book)
        _ = self.sut.reduce(into: &state, action: .feedback(.didFailToLoad))

        _ = self.sut.reduce(into: &state, action: .view(.didDismissLoadFailure))

        XCTAssertFalse(state.hasLoadFailure)
    }

    func test_로드된뒤저장하면_저장을낸다() {
        var state = self.makeLoadedState()

        let effects = self.sut.reduce(into: &state, action: .view(.save("고친 메모")))

        XCTAssertEqual(effects, [.saveMemo(self.book, text: "고친 메모")])
        XCTAssertTrue(state.isSaving)
    }

    func test_로드전에저장하면_아무것도하지않는다() {
        var state = MemoEditReducer.State(book: self.book)

        let effects = self.sut.reduce(into: &state, action: .view(.save("새 메모")))

        XCTAssertEqual(effects, [])
        XCTAssertFalse(state.isSaving)
    }

    func test_저장중에다시저장하면_중복으로내지않는다() {
        var state = self.makeLoadedState()
        _ = self.sut.reduce(into: &state, action: .view(.save("첫번째")))

        let effects = self.sut.reduce(into: &state, action: .view(.save("두번째")))

        XCTAssertEqual(effects, [])
    }

    func test_저장이성공하면_화면을닫는다() {
        var state = self.makeLoadedState()
        _ = self.sut.reduce(into: &state, action: .view(.save("고친 메모")))

        let effects = self.sut.reduce(into: &state, action: .feedback(.didSave))

        XCTAssertEqual(effects, [.delegate(.didFinish)])
    }

    func test_저장이실패하면_저장중표시를풀고실패를알린다() {
        var state = self.makeLoadedState()
        _ = self.sut.reduce(into: &state, action: .view(.save("고친 메모")))

        _ = self.sut.reduce(into: &state, action: .feedback(.didFailToSave))

        XCTAssertFalse(state.isSaving)
        XCTAssertTrue(state.hasSaveFailure)
    }

    func test_저장에실패한뒤_다시저장할수있다() {
        var state = self.makeLoadedState()
        _ = self.sut.reduce(into: &state, action: .view(.save("고친 메모")))
        _ = self.sut.reduce(into: &state, action: .feedback(.didFailToSave))

        let effects = self.sut.reduce(into: &state, action: .view(.save("다시 시도")))

        XCTAssertEqual(effects, [.saveMemo(self.book, text: "다시 시도")])
    }

    func test_저장실패알림을닫으면_표시가사라진다() {
        var state = self.makeLoadedState()
        _ = self.sut.reduce(into: &state, action: .view(.save("고친 메모")))
        _ = self.sut.reduce(into: &state, action: .feedback(.didFailToSave))

        _ = self.sut.reduce(into: &state, action: .view(.didDismissSaveFailure))

        XCTAssertFalse(state.hasSaveFailure)
    }

    func test_저장된메모가없으면_신규로본다() {
        let state = MemoEditReducer.State(book: self.book)

        XCTAssertTrue(state.isNew)
    }

    func test_저장된메모가있으면_신규가아니다() {
        let state = self.makeLoadedState(savedText: "기존 메모")

        XCTAssertFalse(state.isNew)
    }

    func test_빈메모를읽어오면_여전히신규다() {
        var state = MemoEditReducer.State(book: self.book)

        _ = self.sut.reduce(into: &state, action: .feedback(.memoLoaded(text: "")))

        XCTAssertTrue(state.isNew)
        XCTAssertTrue(state.isLoaded)
    }
}
