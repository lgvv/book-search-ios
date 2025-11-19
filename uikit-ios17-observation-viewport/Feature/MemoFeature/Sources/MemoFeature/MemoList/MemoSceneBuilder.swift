import UIKit

import BookModel
import MemoFeatureInterface

public struct MemoSceneBuilder: MemoSceneBuildable {
    public init() {}

    public func makeScene(onDelegate: @escaping (MemoDelegateAction) -> Void) -> UIViewController {
        let store = MemoStore()
        store.onDelegate = onDelegate
        return MemoViewController(store: store)
    }
}
