import Foundation

import PersistenceInterface
import SharedFoundation
import StorageCatalog
import RecentSearchCore

final class DefaultRecentSearchRepository: RecentSearchRepository {
    private let client: LockIsolated<UserDefaultsClient>

    init(client: UserDefaultsClient) {
        self.client = LockIsolated(client)
    }

    func record(term: String, keeping maxCount: Int) async throws {
        self.client.withValue { client in
            var terms = self.load(from: client)
            terms.removeAll { $0 == term }
            terms.insert(term, at: 0)
            self.save(Array(terms.prefix(maxCount)), to: client)
        }
    }

    func list() async throws -> [String] {
        self.client.withValue { self.load(from: $0) }
    }

    func remove(term: String) async throws {
        self.client.withValue { client in
            var terms = self.load(from: client)
            terms.removeAll { $0 == term }
            self.save(terms, to: client)
        }
    }

    private func load(from client: UserDefaultsClient) -> [String] {
        client.object(StorageKeys.recentSearchTerms) ?? []
    }

    private func save(_ terms: [String], to client: UserDefaultsClient) {
        client.setObject(terms, for: StorageKeys.recentSearchTerms)
    }
}

public func makeRecentSearchRepository(client: UserDefaultsClient) -> any RecentSearchRepository {
    DefaultRecentSearchRepository(client: client)
}
