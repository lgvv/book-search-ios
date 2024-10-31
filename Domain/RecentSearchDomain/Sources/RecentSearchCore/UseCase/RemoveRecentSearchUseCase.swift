import Foundation

struct RemoveRecentSearchUseCase: Sendable {
    let service: DefaultRecentSearchService

    func callAsFunction(_ term: String) async {
        await service.remove(term)
    }
}
