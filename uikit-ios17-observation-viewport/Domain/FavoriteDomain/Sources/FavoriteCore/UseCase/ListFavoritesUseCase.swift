import Foundation

import BookModel

struct ListFavoritesUseCase: Sendable {
    let service: DefaultFavoriteService

    func callAsFunction() async -> [Book] {
        await service.list()
    }
}
