import SwiftUI
import UIKit

import BookModel
import BookDetailFeatureInterface

public struct BookDetailSceneBuilder: BookDetailSceneBuildable {
    public init() {}

    public func makeScene(
        _ payload: BookDetailPayload,
        onDelegate: @escaping (BookDetailDelegateAction) -> Void
    ) -> UIViewController {
        let store = BookDetailStore(payload: payload)
        store.onDelegate = onDelegate
        return UIHostingController(rootView: BookDetailView(store: store))
    }
}
