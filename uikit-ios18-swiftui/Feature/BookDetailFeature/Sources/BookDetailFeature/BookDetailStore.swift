import Foundation

import BookModel
import BookDetailFeatureInterface
import DependencyResolver
import FavoriteCore
import MemoCore
import RecentlyViewedCore
import FeatureSupport

@MainActor
@Observable
final class BookDetailStore {
    @ObservationIgnored var onDelegate: ((BookDetailDelegateAction) -> Void)?

    private(set) var state: BookDetailReducer.State

    private let reducer = BookDetailReducer()
    private let tasks = TaskScope<BookDetailReducer.CancelID>()
    private let nonCancellables = NonCancellableTaskQueue<BookDetailReducer.CancelID>()
    private let queue = ActionQueue<BookDetailReducer.Action>()

    @ObservationIgnored @Resolved(FavoriteClientKey.self) private var favoriteClient
    @ObservationIgnored @Resolved(MemoClientKey.self) private var memoClient
    @ObservationIgnored @Resolved(RecentlyViewedClientKey.self) private var recentlyViewedClient

    init(payload: BookDetailPayload) {
        state = .init(
            book: payload.book,
            isFavorite: payload.isFavorite,
            memoText: payload.memoText
        )
    }

    func send(_ action: BookDetailReducer.Action.ViewAction) {
        dispatch(.view(action))
    }

    private func dispatch(_ action: BookDetailReducer.Action) {
        queue.send(action) { action in
            reducer.reduce(into: &state, action: action).forEach(handle)
        }
    }

    private func handle(_ effect: BookDetailReducer.Effect) {
        switch effect {
        case let .delegate(action):
            onDelegate?(action)

        case let .cancel(id):
            tasks.cancel(id)

        case let .observeFavorites(isbn):
            tasks.run(.observeFavorites) { [weak self, favoriteClient] in
                for await favorites in favoriteClient.observe() {
                    guard let self else { return }
                    guard let books = favorites.value else { continue }
                    let isFavorite = books.contains { $0.isbn == isbn }
                    dispatch(.feedback(.favoritesChanged(isFavorite: isFavorite)))
                }
            }

        case let .setFavorite(book, isFavorite):
            nonCancellables.enqueue(.setFavorite) { [favoriteClient] in
                if isFavorite {
                    await favoriteClient.submitAdd(book)
                } else {
                    await favoriteClient.submitRemove(book.isbn)
                }
            }

        case let .recordViewed(book):
            nonCancellables.enqueue(.recordViewed) { [recentlyViewedClient] in
                await recentlyViewedClient.record(book)
            }

        case let .observeMemo(isbn):
            tasks.run(.observeMemo) { [weak self, memoClient] in
                for await memoState in memoClient.observe() {
                    guard let self else { return }
                    guard let memos = memoState.value else { continue }
                    let text = memos.first { $0.book.isbn == isbn }?.text ?? ""
                    dispatch(.feedback(.memoChanged(text: text)))
                }
            }

        }
    }
}
