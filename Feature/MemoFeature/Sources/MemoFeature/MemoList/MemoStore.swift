import Foundation

import BookModel
import DependencyResolver
import FavoriteCore
import MemoCore
import MemoFeatureInterface
import FeatureSupport

@MainActor
final class MemoStore {
    var onDelegate: ((MemoDelegateAction) -> Void)?

    private(set) var state = MemoReducer.State() {
        didSet { subscriptions.notify(from: oldValue, to: state) }
    }

    private let subscriptions = StateSubscriptions<MemoReducer.State>()

    func subscribe<Value: Equatable>(
        _ scope: @escaping (MemoReducer.State) -> Value,
        render: @escaping (_ old: Value?, _ new: Value) -> Void
    ) {
        subscriptions.add(scope: scope, current: state, render: render)
    }

    private let reducer = MemoReducer()
    private let tasks = TaskScope<MemoReducer.CancelID>()
    private let nonCancellables = NonCancellableTaskQueue<MemoReducer.CancelID>()
    private let queue = ActionQueue<MemoReducer.Action>()

    @Resolved(MemoClientKey.self) private var memoClient
    @Resolved(FavoriteClientKey.self) private var favoriteClient

    func send(_ action: MemoReducer.Action.ViewAction) {
        dispatch(.view(action))
    }

    private func dispatch(_ action: MemoReducer.Action) {
        queue.send(action) { action in
            reducer.reduce(into: &state, action: action).forEach(handle)
        }
    }

    private func handle(_ effect: MemoReducer.Effect) {
        switch effect {
        case let .delegate(action):
            onDelegate?(action)

        case .observeMemos:
            tasks.run(.observeMemos) { [weak self, memoClient] in
                for await memos in memoClient.observe().values {
                    guard let self else { return }
                    dispatch(.feedback(.memosChanged(memos)))
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

        case .reloadMemos:
            nonCancellables.enqueue(.reloadMemos) { [memoClient] in
                await memoClient.reload()
            }

        case let .setFavorite(book, isFavorite):
            nonCancellables.enqueue(.setFavorite) { [favoriteClient] in
                if isFavorite {
                    await favoriteClient.submitAdd(book)
                } else {
                    await favoriteClient.submitRemove(book.isbn)
                }
            }
        }
    }
}
