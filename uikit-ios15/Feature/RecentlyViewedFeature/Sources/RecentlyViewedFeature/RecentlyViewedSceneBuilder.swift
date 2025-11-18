import UIKit

import BookModel
import RecentlyViewedFeatureInterface

public struct RecentlyViewedSceneBuilder: RecentlyViewedSceneBuildable {
    public init() {}

    public func makeScene(
        onDelegate: @escaping (RecentlyViewedDelegateAction) -> Void
    ) -> UIViewController {
        let store = RecentlyViewedStore()
        store.onDelegate = onDelegate
        return RecentlyViewedViewController(store: store)
    }
}
