import Foundation

import BookModel

extension FavoriteClient {
    public static func liveValue(repository: any FavoriteRepository) -> Self {
        let service = DefaultFavoriteService(repository: repository)
        let addFavorite = AddFavoriteUseCase(service: service)
        let removeFavorite = RemoveFavoriteUseCase(service: service)
        let listFavorites = ListFavoritesUseCase(service: service)
        let checkFavorite = CheckFavoriteUseCase(service: service)
        let observeFavorites = ObserveFavoritesUseCase(service: service)
        return FavoriteClient(
            submitAdd: { await addFavorite($0) },
            submitRemove: { await removeFavorite(isbn: $0) },
            list: { await listFavorites() },
            isFavorite: { await checkFavorite(isbn: $0) },
            observe: { observeFavorites() },
            observeFailures: { service.observeFailures() },
            reload: { await service.reload() },
            start: { await service.start() }
        )
    }
}
