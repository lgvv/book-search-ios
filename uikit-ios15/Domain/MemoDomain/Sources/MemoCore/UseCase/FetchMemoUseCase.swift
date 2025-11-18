import Foundation

import MemoModel

struct FetchMemoUseCase: Sendable {
    let service: DefaultMemoService

    func callAsFunction(isbn: String) async throws -> MemoLookup {
        try await service.memo(isbn)
    }
}
