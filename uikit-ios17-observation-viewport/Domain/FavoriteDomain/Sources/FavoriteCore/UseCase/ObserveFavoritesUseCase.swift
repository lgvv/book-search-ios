import Combine
import Foundation

import BookModel
import SharedFoundation

struct ObserveFavoritesUseCase: Sendable {
    let service: DefaultFavoriteService

    func callAsFunction() -> AnyPublisher<ResourceState<[Book]>, Never> {
        service.observe()
    }
}
