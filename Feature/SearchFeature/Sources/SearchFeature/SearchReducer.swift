import Foundation

import BookModel
import SearchFeatureInterface
import FeatureSupport

struct SearchReducer: Sendable {

    enum Pagination: Sendable, Equatable {
        case idle
        case loading(isFirstPage: Bool)
        case ready
        case exhausted
        case failed

        var isLoading: Bool {
            if case .loading = self { return true }
            return false
        }
    }

    struct State: Sendable, Equatable {
        var query = ""
        var resultsQuery = ""
        var books: [Book] = []
        var recentTerms: [String] = []
        var favoriteISBNs = Set<String>()
        var memoISBNs = Set<String>()
        var pagination: Pagination = .idle
        var currentPage = 0
        var totalCount = 0
        var seenBookIDs = Set<String>()

        var consecutiveEmptyPages = 0

        var isShowingRecents: Bool { query.isEmpty }
    }

    private static let maxConsecutiveEmptyPages = 3

    enum Action: Sendable {
        case view(ViewAction)
        case feedback(FeedbackAction)

        enum ViewAction: Sendable {
            case viewDidLoad
            case queryChanged(String)
            case submitQuery(String)
            case reachedNearBottom
            case retryPagination
            case removeRecentTerm(String)
            case toggleFavorite(Book)
            case selectBook(Book)
        }

        enum FeedbackAction: Sendable {
            case searchResponse(requestQuery: String, SearchPageResult)
            case recentTermsLoaded([String])
            case favoritesChanged(Set<String>)
            case memosChanged(Set<String>)
        }
    }

    enum SearchPageResult: Sendable {
        case success(books: [Book], pageNo: Int, totalCount: Int, hasNext: Bool)
        case failure
    }

    enum CancelID: Hashable, Sendable {
        case search
        case observeFavorites
        case observeMemos
        case setFavorite
        case recentTerms
    }

    enum Effect: Sendable, Equatable {
        case delegate(SearchDelegateAction)
        case cancel(CancelID)
        case search(query: String, page: Int)
        case searchDebounced(query: String)
        case recordRecentTerm(String)
        case loadRecentTerms
        case removeRecentTerm(String)
        case observeFavorites
        case setFavorite(Book, to: Bool)
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

    private static func resetPaging(_ state: inout State) {
        state.currentPage = 0
        state.totalCount = 0
        state.consecutiveEmptyPages = 0
    }

    private static func loadNextPage(into state: inout State) -> Effect {
        let nextPage = state.currentPage + 1
        state.pagination = .loading(isFirstPage: nextPage == 1)
        return .search(query: state.query, page: nextPage)
    }
}
