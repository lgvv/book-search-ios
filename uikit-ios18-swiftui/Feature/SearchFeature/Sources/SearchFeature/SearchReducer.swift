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

        var emptyState: EmptyState? {
            guard books.isEmpty else { return nil }
            switch pagination {
            case .failed:
                return .failed
            case .exhausted where !query.isEmpty:
                return .noResults
            default:
                return nil
            }
        }

        var pagingFooter: PagingFooter? {
            guard !books.isEmpty else { return nil }
            switch pagination {
            case .loading(isFirstPage: false):
                return .loading
            case .failed:
                return .failed
            default:
                return nil
            }
        }
    }

    enum EmptyState: Sendable, Equatable {
        case noResults
        case failed
    }

    enum PagingFooter: Sendable, Equatable {
        case loading
        case failed
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

    private func reduceView(into state: inout State, action: Action.ViewAction) -> [Effect] {
        switch action {
        case .viewDidLoad:
            return [
                .loadRecentTerms,
                .observeFavorites,
                .observeMemos
            ]

        case let .queryChanged(rawQuery):
            let query = rawQuery.trimmed
            guard query != state.query else { return [] }
            state.query = query
            Self.resetPaging(&state)

            guard !query.isEmpty else {
                state.books = []
                state.seenBookIDs = []
                state.resultsQuery = ""
                state.pagination = .idle
                return [.cancel(.search)]
            }

            state.pagination = .loading(isFirstPage: true)
            return [
                .searchDebounced(query: query)
            ]

        case let .submitQuery(rawQuery):
            let query = rawQuery.trimmed
            guard !query.isEmpty else { return [] }

            var effects: [Effect] = [.recordRecentTerm(query)]

            guard query != state.query || state.books.isEmpty else { return effects }

            state.query = query
            Self.resetPaging(&state)
            state.pagination = .loading(isFirstPage: true)
            effects.append(.search(query: query, page: 1))
            return effects

        case .reachedNearBottom:
            guard case .ready = state.pagination, !state.query.isEmpty else { return [] }
            return [Self.loadNextPage(into: &state)]

        case .retryPagination:
            guard case .failed = state.pagination, !state.query.isEmpty else { return [] }
            return [Self.loadNextPage(into: &state)]

        case let .removeRecentTerm(term):
            return [
                .removeRecentTerm(term)
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

    private func reduceFeedback(into state: inout State, action: Action.FeedbackAction) -> [Effect] {
        switch action {
        case let .searchResponse(requestQuery, result):
            guard requestQuery == state.query else { return [] }

            switch result {
            case let .success(books, pageNo, totalCount, hasNext):
                state.currentPage = pageNo
                state.totalCount = totalCount

                if pageNo == 1 {
                    state.books = []
                    state.seenBookIDs = []
                    state.resultsQuery = requestQuery
                }

                let fresh = books.filter { state.seenBookIDs.insert($0.id).inserted }
                state.books += fresh

                let isLastPage = books.isEmpty
                    || !hasNext
                    || state.books.count >= totalCount
                if isLastPage {
                    state.pagination = .exhausted
                    state.consecutiveEmptyPages = 0
                    return []
                }

                if fresh.isEmpty {
                    state.consecutiveEmptyPages += 1
                    guard state.consecutiveEmptyPages < Self.maxConsecutiveEmptyPages else {
                        state.pagination = .exhausted
                        return []
                    }
                    return [Self.loadNextPage(into: &state)]
                }

                state.consecutiveEmptyPages = 0
                state.pagination = .ready

            case .failure:
                if state.resultsQuery != state.query {
                    state.books = []
                    state.seenBookIDs = []
                }
                state.pagination = .failed
            }
            return []

        case let .recentTermsLoaded(terms):
            state.recentTerms = terms
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
