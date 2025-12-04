import Foundation
import SwiftData

import PersistenceInterface

@ModelActor
actor DefaultSwiftDataStore: SwiftDataStore {
    func perform<T: Sendable>(
        _ block: @escaping @Sendable (ModelContext) throws -> T
    ) async throws -> T {
        try block(self.modelContext)
    }
}
