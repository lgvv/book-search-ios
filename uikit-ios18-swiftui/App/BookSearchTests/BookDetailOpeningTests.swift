import Foundation
import Testing

import BookDetailFeatureInterface
import BookModel
import FavoriteCore
import MemoCore
import MemoModel
import RecentlyViewedCore
import SharedFoundation
import TestSupport

@testable import BookSearch

struct BookDetailOpeningTests {

    private let pachinko = Book(isbn: "1", title: "파친코", author: "이민진")

    private func open(
        _ book: Book,
        recorded: Locked<[String]>,
        recordFails: Bool = false
    ) async -> BookDetailPayload {
        await BookDetailPayload.make(
            book: book,
            favoriteClient: Self.favoriteClient(),
            memoClient: Self.memoClient(),
            recentlyViewedClient: Self.recentlyViewedClient(recorded: recorded, fails: recordFails)
        )
    }

    @Test
    func 상세를열면_열람을한번기록한다() async {
        let recorded = Locked<[String]>([])

        _ = await self.open(self.pachinko, recorded: recorded)

        #expect(recorded.value == ["1"])
    }

    @Test
    func 상세를두번열면_두번기록한다() async {
        let recorded = Locked<[String]>([])

        _ = await self.open(self.pachinko, recorded: recorded)
        _ = await self.open(self.pachinko, recorded: recorded)

        #expect(recorded.value == ["1", "1"])
    }

    @Test
    func 표지와서지는_기록과무관하게채워진다() async {
        let recorded = Locked<[String]>([])

        let payload = await self.open(self.pachinko, recorded: recorded)

        #expect(payload.book.isbn == "1")
        #expect(payload.isFavorite)
        #expect(payload.memoText == "좋았다")
    }

    private static func favoriteClient() -> FavoriteClient {
        FavoriteClient(
            submitAdd: { _ in },
            submitRemove: { _ in },
            list: { [] },
            isFavorite: { _ in true },
            observe: { AsyncStream { $0.finish() } },
            observeFailures: { AsyncStream { $0.finish() } },
            reload: {},
            start: {}
        )
    }

    private static func memoClient() -> MemoClient {
        MemoClient(
            save: { _, _ in },
            list: { [] },
            memo: { isbn in
                .found(
                    BookMemo(
                        book: Book(isbn: isbn, title: "파친코"),
                        text: "좋았다",
                        updatedAt: Date(timeIntervalSince1970: 0)
                    )
                )
            },
            observe: { AsyncStream { $0.finish() } },
            reload: {},
            start: {}
        )
    }

    private static func recentlyViewedClient(
        recorded: Locked<[String]>,
        fails: Bool
    ) -> RecentlyViewedClient {
        RecentlyViewedClient(
            record: { book in
                guard !fails else { return }
                recorded.withValue { $0.append(book.isbn) }
            },
            list: { [] },
            remove: { _ in },
            clear: {},
            observe: { AsyncStream { $0.finish() } },
            reload: {},
            start: {}
        )
    }
}
