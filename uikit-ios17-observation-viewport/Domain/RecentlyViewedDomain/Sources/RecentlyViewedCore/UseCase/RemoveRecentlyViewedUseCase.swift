import Foundation

struct RemoveRecentlyViewedUseCase: Sendable {
    let service: DefaultRecentlyViewedService

    func callAsFunction(isbn: String) async {
        await service.remove(isbn: isbn)
    }
}
