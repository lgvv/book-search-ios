import Foundation

import BookModel
import MemoFeatureInterface

struct MemoEditReducer: Sendable {

    struct State: Sendable, Equatable {
        let book: Book
        var savedText = ""
        var isLoaded = false
        var hasLoadFailure = false
        var isSaving = false
        var hasSaveFailure = false

        var isNew: Bool { savedText.isEmpty }

        init(book: Book) {
            self.book = book
        }
    }

    enum Action: Sendable {
        case view(ViewAction)
        case feedback(FeedbackAction)

        enum ViewAction: Sendable {
            case start
            case retryLoad
            case didDismissLoadFailure
            case save(String)
            case didDismissSaveFailure
        }

        enum FeedbackAction: Sendable {
            case memoLoaded(text: String)
            case didFailToLoad
            case didSave
            case didFailToSave
        }
    }

    enum CancelID: Hashable, Sendable {
        case loadMemo
        case saveMemo
    }

    enum Effect: Sendable, Equatable {
        case delegate(MemoEditDelegateAction)
        case loadMemo(isbn: String)
        case saveMemo(Book, text: String)
    }

    func reduce(into state: inout State, action: Action) -> [Effect] {
        switch action {
        case let .view(action):
            return reduceView(into: &state, action: action)
        case let .feedback(action):
            return reduceFeedback(into: &state, action: action)
        }
    }

    private func reduceView(into state: inout State, action: Action.ViewAction) -> [Effect] {
        switch action {
        case .start:
            return [
                .loadMemo(isbn: state.book.isbn)
            ]

        case .retryLoad:
            guard !state.isLoaded else { return [] }
            state.hasLoadFailure = false
            return [
                .loadMemo(isbn: state.book.isbn)
            ]

        case .didDismissLoadFailure:
            state.hasLoadFailure = false
            return []

        case let .save(text):
            guard state.isLoaded, !state.isSaving else { return [] }
            state.isSaving = true
            return [
                .saveMemo(state.book, text: text)
            ]

        case .didDismissSaveFailure:
            state.hasSaveFailure = false
            return []
        }
    }

    private func reduceFeedback(into state: inout State, action: Action.FeedbackAction) -> [Effect] {
        switch action {
        case let .memoLoaded(text):
            state.savedText = text
            state.isLoaded = true
            state.hasLoadFailure = false
            return []

        case .didFailToLoad:
            state.hasLoadFailure = true
            return []

        case .didSave:
            return [
                .delegate(.didFinish)
            ]

        case .didFailToSave:
            state.isSaving = false
            state.hasSaveFailure = true
            return []
        }
    }
}
