import Foundation

struct RecordRecentSearchUseCase: Sendable {
    let service: DefaultRecentSearchService

    func callAsFunction(_ term: String) async {
        await service.record(term)
    }
}
