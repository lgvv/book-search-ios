import Foundation

public protocol RecentSearchRepository: Sendable {
    func record(term: String, keeping maxCount: Int) async throws
    func list() async throws -> [String]
    func remove(term: String) async throws
}

struct DefaultRecentSearchService: Sendable {
    let repository: any RecentSearchRepository
    let maxCount: Int

    func record(_ term: String) async {
        try? await self.repository.record(term: term, keeping: self.maxCount)
    }

    func list() async -> [String] {
        (try? await self.repository.list()) ?? []
    }

    func remove(_ term: String) async {
        try? await self.repository.remove(term: term)
    }
}
