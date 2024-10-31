import Foundation

struct ListRecentSearchesUseCase: Sendable {
    let service: DefaultRecentSearchService

    func callAsFunction() async -> [String] {
        await service.list()
    }
}
