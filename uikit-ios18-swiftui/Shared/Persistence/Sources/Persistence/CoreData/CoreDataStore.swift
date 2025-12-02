import CoreData
import Foundation

import PersistenceInterface

final class DefaultCoreDataStore: CoreDataStore, @unchecked Sendable {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext

    init(name: String, schema: CoreDataSchema, inMemory: Bool = false) {
        self.container = NSPersistentContainer(name: name, managedObjectModel: schema.current)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            self.container.persistentStoreDescriptions = [description]
        } else {
            for description in self.container.persistentStoreDescriptions {
                guard let url = description.url else { continue }
                try? CoreDataMigrator.migrateIfNeeded(
                    storeAt: url,
                    storeName: name,
                    schema: schema
                )
            }
        }

        var loadError: Error?
        self.container.loadPersistentStores { _, error in loadError = error }
        if let loadError {
            fatalError("CoreData store 로드 실패(\(name)): \(loadError)")
        }

        self.context = self.container.newBackgroundContext()
        self.context.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
    }

    func perform<T: Sendable>(
        _ block: @escaping @Sendable (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        let context = self.context
        return try await context.perform {
            try block(context)
        }
    }
}
