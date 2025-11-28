import Foundation

import RecentlyViewedModel
import SharedFoundation

struct ObserveRecentlyViewedUseCase: Sendable {
    let service: DefaultRecentlyViewedService

    func callAsFunction() -> AsyncStream<ResourceState<[ViewedBook]>> {
        service.observe()
    }
}
