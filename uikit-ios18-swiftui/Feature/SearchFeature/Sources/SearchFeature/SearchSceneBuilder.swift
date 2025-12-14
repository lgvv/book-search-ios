import SwiftUI
import UIKit

import BookModel
import SearchFeatureInterface

public struct SearchSceneBuilder: SearchSceneBuildable {
    public init() {}

    public func makeScene(onDelegate: @escaping (SearchDelegateAction) -> Void) -> UIViewController {
        let store = SearchStore()
        store.onDelegate = onDelegate
        return UIHostingController(rootView: SearchView(store: store))
    }
}
