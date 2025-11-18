import Foundation

extension RecentSearchClient {
    public static func liveValue(repository: any RecentSearchRepository, maxCount: Int = 10) -> Self {
        let service = DefaultRecentSearchService(repository: repository, maxCount: maxCount)
        let recordRecentSearch = RecordRecentSearchUseCase(service: service)
        let listRecentSearches = ListRecentSearchesUseCase(service: service)
        let removeRecentSearch = RemoveRecentSearchUseCase(service: service)
        return RecentSearchClient(
            record: { await recordRecentSearch($0) },
            list: { await listRecentSearches() },
            remove: { await removeRecentSearch($0) }
        )
    }
}
