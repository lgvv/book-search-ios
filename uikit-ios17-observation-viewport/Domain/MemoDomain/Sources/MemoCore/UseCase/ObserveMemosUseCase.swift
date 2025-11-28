import Foundation

import MemoModel
import SharedFoundation

struct ObserveMemosUseCase: Sendable {
    let service: DefaultMemoService

    func callAsFunction() -> AsyncStream<ResourceState<[BookMemo]>> {
        service.observe()
    }
}
