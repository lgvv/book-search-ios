import Foundation

import BookModel
import RecentlyViewedFeatureInterface
import RecentlyViewedModel
import SharedFoundation

struct RecentlyViewedReducer: Sendable {

    struct State: Sendable, Equatable {
        var items: ResourceState<[ViewedBook]> = .loading
        var favoriteISBNs = Set<String>()
        var memoISBNs = Set<String>()

        var canClear: Bool { !(items.value ?? []).isEmpty }
    }

    enum Action: Sendable {
        case view(ViewAction)
        case feedback(FeedbackAction)

        enum ViewAction: Sendable {
            case viewDidLoad
            case retryLoad
            case selectBook(Book)
            case removeItem(isbn: String)
            case confirmClearAll
        }

        enum FeedbackAction: Sendable {
            case itemsChanged(ResourceState<[ViewedBook]>)
            case favoritesChanged(Set<String>)
            case memosChanged(Set<String>)
        }
    }

    enum CancelID: Hashable, Sendable {
        case observeItems
        case observeFavorites
        case observeMemos
        case reloadItems
        case removeItem
        case clearAll
    }

    enum Effect: Sendable, Equatable {
        case delegate(RecentlyViewedDelegateAction)
        case cancel(CancelID)
        case observeItems
        case observeFavorites
        case observeMemos
        case reloadItems
        case removeItem(isbn: String)
        case clearAll
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
        case .viewDidLoad:
            return [.observeItems, .observeFavorites, .observeMemos]

        case .retryLoad:
            return [.reloadItems]

        case let .selectBook(book):
            return [.delegate(.didSelectBook(book))]

        case let .removeItem(isbn):
            return [.removeItem(isbn: isbn)]

        case .confirmClearAll:
            return [.clearAll]
        }
    }

    private func reduceFeedback(into state: inout State, action: Action.FeedbackAction) -> [Effect] {
        switch action {
        case let .itemsChanged(items):
            state.items = items
            return []

        case let .favoritesChanged(isbns):
            state.favoriteISBNs = isbns
            return []

        case let .memosChanged(isbns):
            state.memoISBNs = isbns
            return []
        }
    }
}
