import UIKit

import BookDetailFeatureInterface
import BookModel
import DependencyResolver
import FavoriteCore
import MemoCore
import RecentlyViewedCore
import MemoModel

struct BookDetailRoute: Route {
    let book: Book

    @Resolved(FavoriteClientKey.self) private var favoriteClient
    @Resolved(MemoClientKey.self) private var memoClient
    @Resolved(RecentlyViewedClientKey.self) private var recentlyViewedClient

    var presentation: RoutePresentation { .push }

    func makeViewController(context: RouteContext) async -> UIViewController? {
        let payload = await BookDetailPayload.make(
            book: self.book,
            favoriteClient: self.favoriteClient,
            memoClient: self.memoClient,
            recentlyViewedClient: self.recentlyViewedClient
        )

        let navigator = context.navigator
        return context.scenes.makeBookDetailScene(payload) { [weak navigator] book in
            navigator?.navigate(to: MemoEditRoute(book: book))
        }
    }
}
