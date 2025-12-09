import UIKit

import BookDetailFeatureInterface
import BookModel
import BookCore
import DependencyResolver
import FavoriteCore
import MemoCore
import RecentlyViewedCore
import MemoModel

struct BookDetailByISBNRoute: Route {
    let isbn: String

    @Resolved(BookSearchClientKey.self) private var bookSearchClient
    @Resolved(FavoriteClientKey.self) private var favoriteClient
    @Resolved(MemoClientKey.self) private var memoClient
    @Resolved(RecentlyViewedClientKey.self) private var recentlyViewedClient

    var presentation: RoutePresentation { .modal }

    var failureMessage: RouteFailureMessage? {
        RouteFailureMessage(
            notFound: "책 정보를 찾을 수 없습니다.",
            unavailable: "책 정보를 불러오지 못했습니다.\n잠시 후 다시 시도해 주세요."
        )
    }

    func makeViewController(context: RouteContext) async throws -> UIViewController? {
        guard let book = try await self.bookSearchClient.book(self.isbn) else { return nil }

        let payload = await BookDetailPayload.make(
            book: book,
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
