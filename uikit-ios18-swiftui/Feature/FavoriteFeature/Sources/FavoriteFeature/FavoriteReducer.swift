import Foundation

import BookModel
import FavoriteFeatureInterface
import SharedFoundation

struct FavoriteReducer: Sendable {

    struct State: Sendable, Equatable {
        var books: ResourceState<[Book]> = .loading
        var memoISBNs = Set<String>()
    }

    enum Action: Sendable {
        case view(ViewAction)
        case feedback(FeedbackAction)

        enum ViewAction: Sendable {
            case start
            case retryLoad
            case removeFavorite(Book)
            case selectBook(Book)
        }

        enum FeedbackAction: Sendable {
            case favoritesChanged(ResourceState<[Book]>)
            case memosChanged(Set<String>)
        }
    }

    enum CancelID: Hashable, Sendable {
        case observeFavorites
        case observeMemos
        case removeFavorite
        case reloadFavorites
    }

    enum Effect: Sendable, Equatable {
        case delegate(FavoriteDelegateAction)
        case cancel(CancelID)
        case observeFavorites
        case reloadFavorites
        case removeFavorite(isbn: String)
        case observeMemos
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
                .observeFavorites,
                .observeMemos
            ]

        case .retryLoad:
            return [
                .reloadFavorites
            ]

        case let .removeFavorite(book):
            return [
                .removeFavorite(isbn: book.isbn)
            ]

        case let .selectBook(book):
            return [
                .delegate(.didSelectBook(book))
            ]
        }
    }

    private func reduceFeedback(into state: inout State, action: Action.FeedbackAction) -> [Effect] {
        switch action {
        case let .favoritesChanged(books):
            state.books = books
            return []

        case let .memosChanged(isbns):
            state.memoISBNs = isbns
            return []
        }
    }
}
