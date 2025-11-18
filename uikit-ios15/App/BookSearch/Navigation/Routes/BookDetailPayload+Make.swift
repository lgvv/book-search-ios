import Foundation

import BookDetailFeatureInterface
import BookModel
import FavoriteCore
import MemoCore
import MemoModel

extension BookDetailPayload {
    static func make(
        book: Book,
        favoriteClient: FavoriteClient,
        memoClient: MemoClient
    ) async -> Self {
        async let isFavorite = favoriteClient.isFavorite(book.isbn)
        let memoText = ((try? await memoClient.memo(book.isbn))?.memo?.text) ?? ""

        return await BookDetailPayload(
            book: book,
            isFavorite: isFavorite,
            memoText: memoText
        )
    }
}
