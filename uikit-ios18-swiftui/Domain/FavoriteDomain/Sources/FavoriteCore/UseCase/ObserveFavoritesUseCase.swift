import Foundation

import BookModel
import SharedFoundation

struct ObserveFavoritesUseCase: Sendable {
    let service: DefaultFavoriteService

    func callAsFunction() -> AsyncStream<ResourceState<[Book]>> {
        service.observe()
    }
}
