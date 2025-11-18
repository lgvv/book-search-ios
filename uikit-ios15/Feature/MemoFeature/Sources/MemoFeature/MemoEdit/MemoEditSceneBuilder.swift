import UIKit

import BookModel
import MemoFeatureInterface

public struct MemoEditSceneBuilder: MemoEditSceneBuildable {
    public init() {}

    public func makeScene(
        book: Book,
        onDelegate: @escaping (MemoEditDelegateAction) -> Void
    ) -> UIViewController {
        let store = MemoEditStore(book: book)
        store.onDelegate = onDelegate
        return MemoEditViewController(store: store)
    }
}
