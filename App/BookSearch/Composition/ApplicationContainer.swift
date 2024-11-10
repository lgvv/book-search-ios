import Foundation

import BookCore
import BookData
import DependencyResolver
import FavoriteCore
import FavoriteData
import ImageLoader
import ImageLoaderContainer
import MemoCore
import MemoData
import MockServer
import Networks
import NetworksInterface
import Persistence
import PersistenceInterface
import RecentSearchCore
import RecentSearchData
import SearchFeature

@MainActor
final class ApplicationContainer {
    let searchSceneBuilder: SearchSceneBuilder

    private let client: UserDefaultsClient

    let favoriteClient: FavoriteClient
    private let memoClient: MemoClient

    private var didStart = false

    init() {
        let client = UserDefaultsClient.live(suiteName: AppEnvironment.storageSuiteName)
        self.client = client

        ImageLoaderContainer.bootstrap(
            dataLoader: .networks(client: .live),
            diskClient: .caches(directoryName: AppEnvironment.imageCacheDirectoryName)
        )

        let mockSession = MockServer.install(.init(storeFactory: .live))
        let httpClient = HTTPClient.live.replacingTransport(URLSessionTransport(urlSession: mockSession))

        var values = ResolverValues()
        values[BookSearchClientKey.self] = .liveValue(
            repository: makeBookRepository(httpClient: httpClient, baseURL: MockServer.baseURL)
        )
        values[RecentSearchClientKey.self] = .liveValue(repository: makeRecentSearchRepository(client: client))

        let favoriteClient = FavoriteClient.liveValue(
            repository: makeFavoriteRepository(httpClient: httpClient, baseURL: MockServer.baseURL)
        )
        let memoClient = MemoClient.liveValue(repository: makeMemoRepository(storeFactory: .live))
        self.favoriteClient = favoriteClient
        self.memoClient = memoClient

        values[FavoriteClientKey.self] = favoriteClient
        values[MemoClientKey.self] = memoClient
        Resolver.install(values)

        self.searchSceneBuilder = SearchSceneBuilder()
    }

    func start() {
        precondition(!self.didStart, "ApplicationContainer.start()는 프로세스당 1회만 호출한다")
        self.didStart = true

        Task { [favoriteClient, memoClient] in
            async let favorite: Void = favoriteClient.start()
            async let memo: Void = memoClient.start()
            _ = await (favorite, memo)
        }
    }
}
