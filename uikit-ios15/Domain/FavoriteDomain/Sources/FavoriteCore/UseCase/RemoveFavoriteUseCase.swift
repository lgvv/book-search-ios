import Foundation

struct RemoveFavoriteUseCase: Sendable {
    let service: DefaultFavoriteService

    func callAsFunction(isbn: String) async {
        await service.remove(isbn: isbn)
    }
}
