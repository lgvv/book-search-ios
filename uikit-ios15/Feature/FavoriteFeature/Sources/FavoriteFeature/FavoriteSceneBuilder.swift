import UIKit

import BookModel
import FavoriteFeatureInterface

public struct FavoriteSceneBuilder: FavoriteSceneBuildable {
    public init() {}

    public func makeScene(onDelegate: @escaping (FavoriteDelegateAction) -> Void) -> UIViewController {
        let store = FavoriteStore()
        store.onDelegate = onDelegate
        return FavoriteViewController(store: store)
    }
}
