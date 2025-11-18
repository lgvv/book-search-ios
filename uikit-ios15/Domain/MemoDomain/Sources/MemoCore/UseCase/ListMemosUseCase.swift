import Foundation

import MemoModel

struct ListMemosUseCase: Sendable {
    let service: DefaultMemoService

    func callAsFunction() async -> [BookMemo] {
        await service.list()
    }
}
