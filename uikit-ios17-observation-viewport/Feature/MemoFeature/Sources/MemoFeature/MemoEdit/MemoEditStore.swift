import Foundation

import BookModel
import DependencyResolver
import MemoCore
import MemoFeatureInterface
import FeatureSupport

@MainActor
@Observable
final class MemoEditStore {
    @ObservationIgnored var onDelegate: ((MemoEditDelegateAction) -> Void)?

    private(set) var state: MemoEditReducer.State

    private let reducer = MemoEditReducer()
    private let tasks = TaskScope<MemoEditReducer.CancelID>()
    private let nonCancellables = NonCancellableTaskQueue<MemoEditReducer.CancelID>()
    private let queue = ActionQueue<MemoEditReducer.Action>()

    @ObservationIgnored @Resolved(MemoClientKey.self) private var memoClient

    init(book: Book) {
        state = .init(book: book)
    }

    func send(_ action: MemoEditReducer.Action.ViewAction) {
        dispatch(.view(action))
    }

    private func dispatch(_ action: MemoEditReducer.Action) {
        queue.send(action) { action in
            reducer.reduce(into: &state, action: action).forEach(handle)
        }
    }

    private func handle(_ effect: MemoEditReducer.Effect) {
        switch effect {
        case let .delegate(action):
            onDelegate?(action)

        case let .loadMemo(isbn):
            tasks.run(.loadMemo) { [weak self, memoClient] in
                do {
                    let lookup = try await memoClient.memo(isbn)
                    guard let self else { return }
                    dispatch(.feedback(.memoLoaded(text: lookup.memo?.text ?? "")))
                } catch {
                    guard let self else { return }
                    dispatch(.feedback(.didFailToLoad))
                }
            }

        case let .saveMemo(book, text):
            nonCancellables.enqueue(.saveMemo) { [weak self, memoClient] in
                do {
                    try await memoClient.save(book, text)
                    guard let self else { return }
                    dispatch(.feedback(.didSave))
                } catch {
                    guard let self else { return }
                    dispatch(.feedback(.didFailToSave))
                }
            }
        }
    }
}
