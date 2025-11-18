import Foundation

import RecentlyViewedModel

struct ListRecentlyViewedUseCase: Sendable {
    let service: DefaultRecentlyViewedService

    func callAsFunction() async -> [ViewedBook] {
        await service.list()
    }
}
