import CoreData
import Foundation

public protocol CoreDataStore: Sendable {
    func perform<T: Sendable>(
        _ block: @escaping @Sendable (NSManagedObjectContext) throws -> T
    ) async throws -> T
}

public struct CoreDataSchema: @unchecked Sendable {
    public let versions: [NSManagedObjectModel]

    public var current: NSManagedObjectModel {
        guard let last = self.versions.last else {
            preconditionFailure("CoreDataSchema.versions는 최소 하나여야 한다")
        }
        return last
    }

    public init(versions: [NSManagedObjectModel]) {
        precondition(!versions.isEmpty, "CoreDataSchema.versions는 최소 하나여야 한다")
        self.versions = versions
    }

    public init(_ only: NSManagedObjectModel) {
        self.init(versions: [only])
    }
}

public struct CoreDataStoreFactory: Sendable {
    public var make: @Sendable (_ name: String, _ schema: CoreDataSchema) -> any CoreDataStore

    public init(make: @escaping @Sendable (_ name: String, _ schema: CoreDataSchema) -> any CoreDataStore) {
        self.make = make
    }
}
