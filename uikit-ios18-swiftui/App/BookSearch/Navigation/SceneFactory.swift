import UIKit

import BookDetailFeatureInterface
import BookModel

@MainActor
struct SceneFactory {
    var makeSearchScene: (_ onSelectBook: @escaping (Book) -> Void) -> UIViewController
    var makeFavoriteScene: (_ onSelectBook: @escaping (Book) -> Void) -> UIViewController
    var makeMemoScene: (_ onSelectBook: @escaping (Book) -> Void) -> UIViewController
    var makeRecentlyViewedScene: (_ onSelectBook: @escaping (Book) -> Void) -> UIViewController
    var makeBookDetailScene: (
        _ payload: BookDetailPayload,
        _ onRequestMemoEdit: @escaping (Book) -> Void
    ) -> UIViewController
    var makeMemoEditScene: (
        _ book: Book,
        _ onFinish: @escaping () -> Void
    ) -> UIViewController

    init(
        makeSearchScene: @escaping (_ onSelectBook: @escaping (Book) -> Void) -> UIViewController,
        makeFavoriteScene: @escaping (_ onSelectBook: @escaping (Book) -> Void) -> UIViewController,
        makeMemoScene: @escaping (_ onSelectBook: @escaping (Book) -> Void) -> UIViewController,
        makeRecentlyViewedScene: @escaping (_ onSelectBook: @escaping (Book) -> Void) -> UIViewController,
        makeBookDetailScene: @escaping (
            _ payload: BookDetailPayload,
            _ onRequestMemoEdit: @escaping (Book) -> Void
        ) -> UIViewController,
        makeMemoEditScene: @escaping (
            _ book: Book,
            _ onFinish: @escaping () -> Void
        ) -> UIViewController
    ) {
        self.makeSearchScene = makeSearchScene
        self.makeFavoriteScene = makeFavoriteScene
        self.makeMemoScene = makeMemoScene
        self.makeRecentlyViewedScene = makeRecentlyViewedScene
        self.makeBookDetailScene = makeBookDetailScene
        self.makeMemoEditScene = makeMemoEditScene
    }
}

extension SceneFactory {
    static var testValue: Self {
        Self(
            makeSearchScene: { _ in fatalError("unimplemented: SceneFactory.makeSearchScene") },
            makeFavoriteScene: { _ in fatalError("unimplemented: SceneFactory.makeFavoriteScene") },
            makeMemoScene: { _ in fatalError("unimplemented: SceneFactory.makeMemoScene") },
            makeRecentlyViewedScene: { _ in fatalError("unimplemented: SceneFactory.makeRecentlyViewedScene") },
            makeBookDetailScene: { _, _ in fatalError("unimplemented: SceneFactory.makeBookDetailScene") },
            makeMemoEditScene: { _, _ in fatalError("unimplemented: SceneFactory.makeMemoEditScene") }
        )
    }
}
