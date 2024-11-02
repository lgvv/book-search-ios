import Foundation

struct CheckFavoriteUseCase: Sendable {
    let service: DefaultFavoriteService

    func callAsFunction(isbn: String) async -> Bool {
        await service.isFavorite(isbn)
    }
}
