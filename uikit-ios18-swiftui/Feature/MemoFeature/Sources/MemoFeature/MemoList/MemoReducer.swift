import Foundation

import BookModel
import MemoCore
import MemoModel
import MemoFeatureInterface
import SharedFoundation

struct MemoReducer: Sendable {

    struct State: Sendable, Equatable {
        var memos: ResourceState<[BookMemo]> = .loading
        var favoriteISBNs = Set<String>()
    }

    enum Action: Sendable {
        case view(ViewAction)
        case feedback(FeedbackAction)

        enum ViewAction: Sendable {
            case start
            case retryLoad
            case toggleFavorite(Book)
            case selectBook(Book)
        }

        enum FeedbackAction: Sendable {
            case memosChanged(ResourceState<[BookMemo]>)
            case favoritesChanged(Set<String>)
        }
    }

    enum CancelID: Hashable, Sendable {
        case observeMemos
        case observeFavorites
        case setFavorite
        case reloadMemos
    }

    enum Effect: Sendable, Equatable {
        case delegate(MemoDelegateAction)
        case observeMemos
        case reloadMemos
        case observeFavorites
        case setFavorite(Book, to: Bool)
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
                .observeMemos,
                .observeFavorites
            ]

        case .retryLoad:
            return [
                .reloadMemos
            ]

        case let .toggleFavorite(book):
            let willBeFavorite = !state.favoriteISBNs.contains(book.isbn)
            if willBeFavorite {
                state.favoriteISBNs.insert(book.isbn)
            } else {
                state.favoriteISBNs.remove(book.isbn)
            }
            return [
                .setFavorite(book, to: willBeFavorite)
            ]

        case let .selectBook(book):
            return [
                .delegate(.didSelectBook(book))
            ]
        }
    }

    private func reduceFeedback(into state: inout State, action: Action.FeedbackAction) -> [Effect] {
        switch action {
        case let .memosChanged(memos):
            state.memos = memos
            return []

        case let .favoritesChanged(isbns):
            state.favoriteISBNs = isbns
            return []
        }
    }
}
