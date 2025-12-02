import Foundation

import BookModel

struct AddFavoriteUseCase: Sendable {
    let service: DefaultFavoriteService

    func callAsFunction(_ book: Book) async {
        await service.add(book)
    }
}
