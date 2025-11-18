import Combine
import Foundation

import BookModel
import RecentlyViewedModel

extension RecentlyViewedClient {
    public static func liveValue(
        repository: any RecentlyViewedRepository,
        maxCount: Int = 20
    ) -> Self {
        let service = DefaultRecentlyViewedService(repository: repository, maxCount: maxCount)
        let recordViewedBook = RecordViewedBookUseCase(service: service)
        let listRecentlyViewed = ListRecentlyViewedUseCase(service: service)
        let removeRecentlyViewed = RemoveRecentlyViewedUseCase(service: service)
        let clearRecentlyViewed = ClearRecentlyViewedUseCase(service: service)
        let observeRecentlyViewed = ObserveRecentlyViewedUseCase(service: service)
        return RecentlyViewedClient(
            record: { await recordViewedBook($0) },
            list: { await listRecentlyViewed() },
            remove: { await removeRecentlyViewed(isbn: $0) },
            clear: { await clearRecentlyViewed() },
            observe: { observeRecentlyViewed() },
            reload: { await service.reload() },
            start: { await service.start() }
        )
    }
}
