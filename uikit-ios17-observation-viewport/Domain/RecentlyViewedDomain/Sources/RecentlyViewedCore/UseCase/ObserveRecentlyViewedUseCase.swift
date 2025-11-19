import Combine
import Foundation

import RecentlyViewedModel
import SharedFoundation

struct ObserveRecentlyViewedUseCase: Sendable {
    let service: DefaultRecentlyViewedService

    func callAsFunction() -> AnyPublisher<ResourceState<[ViewedBook]>, Never> {
        service.observe()
    }
}
