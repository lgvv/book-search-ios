import Foundation

import PersistenceInterface
import SharedFoundation

public enum MockServer {
    public struct Configuration: Sendable {
        public var storeFactory: SwiftDataStoreFactory
        public var latencyNanoseconds: UInt64
        public var faultProfile: MockFaultProfile

        public init(
            storeFactory: SwiftDataStoreFactory,
            latencyNanoseconds: UInt64 = 400_000_000,
            faultProfile: MockFaultProfile = .disabled
        ) {
            self.storeFactory = storeFactory
            self.latencyNanoseconds = latencyNanoseconds
            self.faultProfile = faultProfile
        }
    }

    public static let baseURL = URL(string: "https://api.booksearch.dev")!

    public static func install(_ configuration: Configuration) -> URLSession {
        let favoriteStore = FavoriteRecordStore(
            store: configuration.storeFactory.make(FavoriteFakeDB.storeName, FavoriteMigrationPlan.self)
        )

        let router = MockRouter(
            collections: [
                BookSearchHandler(catalog: BookCatalog()),
                FavoriteHandler(store: favoriteStore),
            ],
            middlewares: [
                LatencyMiddleware(nanoseconds: configuration.latencyNanoseconds),
                FaultInjectionMiddleware(profile: configuration.faultProfile),
            ]
        )

        Self.state.withValue { current in
            precondition(current == nil, "MockServer.install은 프로세스당 1회만 호출한다")
            current = router
        }

        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.protocolClasses = [MockServerURLProtocol.self] + (sessionConfiguration.protocolClasses ?? [])
        return URLSession(configuration: sessionConfiguration)
    }

    static var router: MockRouter? { Self.state.value }
    private static let state = LockIsolated<MockRouter?>(nil)
}
