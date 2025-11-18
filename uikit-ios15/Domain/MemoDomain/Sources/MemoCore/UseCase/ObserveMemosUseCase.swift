import Combine
import Foundation

import MemoModel
import SharedFoundation

struct ObserveMemosUseCase: Sendable {
    let service: DefaultMemoService

    func callAsFunction() -> AnyPublisher<ResourceState<[BookMemo]>, Never> {
        service.observe()
    }
}
