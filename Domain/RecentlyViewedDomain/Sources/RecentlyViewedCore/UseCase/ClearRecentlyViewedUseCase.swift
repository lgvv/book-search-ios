import Foundation

struct ClearRecentlyViewedUseCase: Sendable {
    let service: DefaultRecentlyViewedService

    func callAsFunction() async {
        await service.clear()
    }
}
