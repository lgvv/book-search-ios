import Foundation

import BookModel

struct RecordViewedBookUseCase: Sendable {
    let service: DefaultRecentlyViewedService

    func callAsFunction(_ book: Book) async {
        await service.record(book)
    }
}
