import Combine
import Foundation

import BookModel
import MemoModel

extension MemoClient {
    public static func liveValue(repository: any MemoRepository) -> Self {
        let service = DefaultMemoService(repository: repository)
        let saveMemo = SaveMemoUseCase(service: service)
        let listMemos = ListMemosUseCase(service: service)
        let fetchMemo = FetchMemoUseCase(service: service)
        let observeMemos = ObserveMemosUseCase(service: service)
        return MemoClient(
            save: { try await saveMemo($0, text: $1) },
            list: { await listMemos() },
            memo: { try await fetchMemo(isbn: $0) },
            observe: { observeMemos() },
            reload: { await service.reload() },
            start: { await service.start() }
        )
    }
}
