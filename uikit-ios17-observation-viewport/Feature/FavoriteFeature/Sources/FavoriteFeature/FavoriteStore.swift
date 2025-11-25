import Foundation

import BookModel
import DependencyResolver
import FavoriteCore
import FavoriteFeatureInterface
import MemoCore
import FeatureSupport

@MainActor
@Observable
final class FavoriteStore {
    @ObservationIgnored var onDelegate: ((FavoriteDelegateAction) -> Void)?

    private(set) var state = FavoriteReducer.State()

    private let reducer = FavoriteReducer()
    private let tasks = TaskScope<FavoriteReducer.CancelID>()
    private let nonCancellables = NonCancellableTaskQueue<FavoriteReducer.CancelID>()
    private let queue = ActionQueue<FavoriteReducer.Action>()

    @ObservationIgnored @Resolved(FavoriteClientKey.self) private var favoriteClient
    @ObservationIgnored @Resolved(MemoClientKey.self) private var memoClient

    func send(_ action: FavoriteReducer.Action.ViewAction) {
        dispatch(.view(action))
    }

    private func dispatch(_ action: FavoriteReducer.Action) {
        queue.send(action) { action in
            reducer.reduce(into: &state, action: action).forEach(handle)
        }
    }

    private func handle(_ effect: FavoriteReducer.Effect) {
        switch effect {
        case let .delegate(action):
            onDelegate?(action)

        case let .cancel(id):
            tasks.cancel(id)

        case .observeFavorites:
            tasks.run(.observeFavorites) { [weak self, favoriteClient] in
                for await favorites in favoriteClient.observe().values {
                    guard let self else { return }
                    dispatch(.feedback(.favoritesChanged(favorites)))
                }
            }

        case .reloadFavorites:
            nonCancellables.enqueue(.reloadFavorites) { [favoriteClient] in
                await favoriteClient.reload()
            }

        case let .removeFavorite(isbn):
            nonCancellables.enqueue(.removeFavorite) { [favoriteClient] in
                await favoriteClient.submitRemove(isbn)
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
}
