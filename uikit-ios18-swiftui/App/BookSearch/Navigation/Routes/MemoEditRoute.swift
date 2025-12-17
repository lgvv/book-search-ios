import UIKit

import BookModel

struct MemoEditRoute: Route {
    let book: Book

    var presentation: RoutePresentation { .push }

    func makeViewController(context: RouteContext) async -> UIViewController? {
        let navigator = context.navigator
        return context.scenes.makeMemoEditScene(self.book) { [weak navigator] in
            navigator?.pop()
        }
    }
}
