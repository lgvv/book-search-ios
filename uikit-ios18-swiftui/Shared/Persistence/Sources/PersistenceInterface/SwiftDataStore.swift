import Foundation
import SwiftData

public protocol SwiftDataStore: Sendable {
    func perform<T: Sendable>(
        _ block: @escaping @Sendable (ModelContext) throws -> T
    ) async throws -> T
}

public struct SwiftDataStoreFactory: Sendable {
    public var make: @Sendable (
        _ name: String,
        _ migrationPlan: any SchemaMigrationPlan.Type
    ) -> any SwiftDataStore

    public init(
        make: @escaping @Sendable (
            _ name: String,
            _ migrationPlan: any SchemaMigrationPlan.Type
        ) -> any SwiftDataStore
    ) {
        self.make = make
    }
}

extension SchemaMigrationPlan {
    public static var currentSchema: Schema {
        guard let latest = self.schemas.last else {
            preconditionFailure("SchemaMigrationPlan.schemas는 최소 하나여야 한다")
        }
        return Schema(versionedSchema: latest)
    }
}
