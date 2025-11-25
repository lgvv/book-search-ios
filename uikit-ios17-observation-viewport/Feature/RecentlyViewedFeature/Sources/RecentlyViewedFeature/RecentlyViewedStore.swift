import Foundation

import BookModel
import DependencyResolver
import FavoriteCore
import FeatureSupport
import MemoCore
import RecentlyViewedCore
import RecentlyViewedFeatureInterface

@MainActor
@Observable
final class RecentlyViewedStore {
    @ObservationIgnored var onDelegate: ((RecentlyViewedDelegateAction) -> Void)?

    private(set) var state = RecentlyViewedReducer.State()

    private let reducer = RecentlyViewedReducer()
    private let tasks = TaskScope<RecentlyViewedReducer.CancelID>()
    private let nonCancellables = NonCancellableTaskQueue<RecentlyViewedReducer.CancelID>()
    private let queue = ActionQueue<RecentlyViewedReducer.Action>()

    @ObservationIgnored @Resolved(RecentlyViewedClientKey.self) private var recentlyViewedClient
    @ObservationIgnored @Resolved(FavoriteClientKey.self) private var favoriteClient
    @ObservationIgnored @Resolved(MemoClientKey.self) private var memoClient

    func send(_ action: RecentlyViewedReducer.Action.ViewAction) {
        dispatch(.view(action))
    }

    private func dispatch(_ action: RecentlyViewedReducer.Action) {
        queue.send(action) { action in
            reducer.reduce(into: &state, action: action).forEach(handle)
        }
    }

    private func handle(_ effect: RecentlyViewedReducer.Effect) {
        switch effect {
        case let .delegate(action):
            onDelegate?(action)

        case let .cancel(id):
            tasks.cancel(id)

        case .observeItems:
            tasks.run(.observeItems) { [weak self, recentlyViewedClient] in
                for await items in recentlyViewedClient.observe().values {
                    guard let self else { return }
                    dispatch(.feedback(.itemsChanged(items)))
                }
            }

        case .observeFavorites:
            tasks.run(.observeFavorites) { [weak self, favoriteClient] in
                for await favorites in favoriteClient.observe().values {
                    guard let self else { return }
                    guard let books = favorites.value else { continue }
                    dispatch(.feedback(.favoritesChanged(Set(books.map(\.isbn)))))
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

        case .reloadItems:
            nonCancellables.enqueue(.reloadItems) { [recentlyViewedClient] in
                await recentlyViewedClient.reload()
            }

        case let .removeItem(isbn):
            nonCancellables.enqueue(.removeItem) { [recentlyViewedClient] in
                await recentlyViewedClient.remove(isbn)
            }

        case .clearAll:
            nonCancellables.enqueue(.clearAll) { [recentlyViewedClient] in
                await recentlyViewedClient.clear()
            }
        }
    }
}
