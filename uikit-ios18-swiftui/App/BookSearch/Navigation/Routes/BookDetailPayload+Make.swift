import Foundation

import BookDetailFeatureInterface
import BookModel
import FavoriteCore
import MemoCore
import MemoModel
import RecentlyViewedCore

extension BookDetailPayload {
    static func make(
        book: Book,
        favoriteClient: FavoriteClient,
        memoClient: MemoClient,
        recentlyViewedClient: RecentlyViewedClient
    ) async -> Self {
        async let isFavorite = favoriteClient.isFavorite(book.isbn)
        let memoText = ((try? await memoClient.memo(book.isbn))?.memo?.text) ?? ""

        await recentlyViewedClient.record(book)

        return await BookDetailPayload(
            book: book,
            isFavorite: isFavorite,
            memoText: memoText
        )
    }
}
