import Foundation

import BookModel
import BookDetailFeatureInterface

struct BookDetailReducer: Sendable {

    struct State: Sendable, Equatable {
        let book: Book
        var isFavorite = false
        var memoText = ""

        init(book: Book, isFavorite: Bool = false, memoText: String = "") {
            self.book = book
            self.isFavorite = isFavorite
            self.memoText = memoText
        }
    }

    enum Action: Sendable {
        case view(ViewAction)
        case feedback(FeedbackAction)

        enum ViewAction: Sendable {
            case start
            case toggleFavorite
            case editMemo
        }

        enum FeedbackAction: Sendable {
            case favoritesChanged(isFavorite: Bool)
            case memoChanged(text: String)
        }
    }

    enum CancelID: Hashable, Sendable {
        case observeFavorites
        case observeMemo
        case setFavorite
        case recordViewed
    }

    enum Effect: Sendable, Equatable {
        case delegate(BookDetailDelegateAction)
        case cancel(CancelID)
        case observeFavorites(isbn: String)
        case setFavorite(Book, to: Bool)
        case observeMemo(isbn: String)
        case recordViewed(Book)
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
                .observeFavorites(isbn: state.book.isbn),
                .observeMemo(isbn: state.book.isbn),
                .recordViewed(state.book)
            ]

        case .toggleFavorite:
            let willBeFavorite = !state.isFavorite
            state.isFavorite = willBeFavorite
            return [
                .setFavorite(state.book, to: willBeFavorite)
            ]

        case .editMemo:
            return [
                .delegate(.didRequestMemoEdit(state.book))
            ]
        }
    }

    private func reduceFeedback(into state: inout State, action: Action.FeedbackAction) -> [Effect] {
        switch action {
        case let .favoritesChanged(isFavorite):
            state.isFavorite = isFavorite
            return []

        case let .memoChanged(text):
            state.memoText = text
            return []
        }
    }
}
