import Foundation

import BookModel
import SearchFeatureInterface
import BookCore
import DependencyResolver
import FavoriteCore
import MemoCore
import RecentSearchCore
import FeatureSupport

@MainActor
@Observable
final class SearchStore {
    @ObservationIgnored var onDelegate: ((SearchDelegateAction) -> Void)?

    private(set) var state = SearchReducer.State()

    private let reducer = SearchReducer()
    private let tasks = TaskScope<SearchReducer.CancelID>()
    private let nonCancellables = NonCancellableTaskQueue<SearchReducer.CancelID>()
    private let queue = ActionQueue<SearchReducer.Action>()

    @ObservationIgnored @Resolved(BookSearchClientKey.self) private var bookSearchClient
    @ObservationIgnored @Resolved(RecentSearchClientKey.self) private var recentSearchClient
    @ObservationIgnored @Resolved(FavoriteClientKey.self) private var favoriteClient
    @ObservationIgnored @Resolved(MemoClientKey.self) private var memoClient

    func send(_ action: SearchReducer.Action.ViewAction) {
        dispatch(.view(action))
    }

    private func dispatch(_ action: SearchReducer.Action) {
        queue.send(action) { action in
            reducer.reduce(into: &state, action: action).forEach(handle)
        }
    }

    private func handle(_ effect: SearchReducer.Effect) {
        switch effect {
        case let .delegate(action):
            onDelegate?(action)

        case let .cancel(id):
            tasks.cancel(id)

        case let .search(query, page):
            performSearch(query: query, page: page, delayNanoseconds: nil)

        case let .searchDebounced(query):
            performSearch(query: query, page: 1, delayNanoseconds: Self.debounceNanoseconds)

        case .observeFavorites:
            tasks.run(.observeFavorites) { [weak self, favoriteClient] in
                for await favorites in favoriteClient.observe().values {
                    guard let self else { return }
                    guard let books = favorites.value else { continue }
                    dispatch(.feedback(.favoritesChanged(Set(books.map(\.isbn)))))
                }
            }

        case let .recordRecentTerm(term):
            nonCancellables.enqueue(.recentTerms) { [weak self, recentSearchClient] in
                await recentSearchClient.record(term)
                guard let self else { return }
                dispatch(.feedback(.recentTermsLoaded(await recentSearchClient.list())))
            }

        case .loadRecentTerms:
            nonCancellables.enqueue(.recentTerms) { [weak self, recentSearchClient] in
                guard let self else { return }
                dispatch(.feedback(.recentTermsLoaded(await recentSearchClient.list())))
            }

        case let .removeRecentTerm(term):
            nonCancellables.enqueue(.recentTerms) { [weak self, recentSearchClient] in
                await recentSearchClient.remove(term)
                guard let self else { return }
                dispatch(.feedback(.recentTermsLoaded(await recentSearchClient.list())))
            }

        case let .setFavorite(book, isFavorite):
            nonCancellables.enqueue(.setFavorite) { [favoriteClient] in
                if isFavorite {
                    await favoriteClient.submitAdd(book)
                } else {
                    await favoriteClient.submitRemove(book.isbn)
                }
            }

        case .observeMemos:
            tasks.run(.observeMemos) { [weak self, memoClient] in
                for await memoState in memoClient.observe().values {
                    guard let self else { return }
                    guard let memos = memoState.value else { continue }
                    dispatch(.feedback(.memosChanged(Set(memos.map(\.book.isbn)))))
                }
            }
        }
    }

    private static let debounceNanoseconds: UInt64 = 300_000_000

    private func performSearch(query: String, page: Int, delayNanoseconds: UInt64?) {
        tasks.run(.search) { [weak self, bookSearchClient] in
            if let delayNanoseconds {
                do {
                    try await Task.sleep(nanoseconds: delayNanoseconds)
                } catch {
                    return
                }
            }
            do {
                let result = try await bookSearchClient.search(query, page)
                guard !Task.isCancelled, let self else { return }
                dispatch(.feedback(.searchResponse(
                    requestQuery: query,
                    .success(
                        books: result.books,
                        pageNo: result.pageNo,
                        totalCount: result.totalCount,
                        hasNext: result.hasNext
                    )
                )))
            } catch {
                guard !Task.isCancelled, let self else { return }
                dispatch(.feedback(.searchResponse(requestQuery: query, .failure)))
            }
        }
    }
}
