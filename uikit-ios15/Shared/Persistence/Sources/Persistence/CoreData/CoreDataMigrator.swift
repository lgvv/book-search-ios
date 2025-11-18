import CoreData
import Foundation

import PersistenceInterface

enum CoreDataMigrator {
    enum MigrationError: Error {
        case unknownSourceVersion(storeName: String)
        case inferenceFailed(storeName: String, step: Int)
    }

    static func migrateIfNeeded(
        storeAt url: URL,
        storeName: String,
        schema: CoreDataSchema
    ) throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return
        }

        let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
            type: .sqlite,
            at: url
        )

        guard let sourceIndex = schema.versions.firstIndex(where: {
            $0.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
        }) else {
            throw MigrationError.unknownSourceVersion(storeName: storeName)
        }

        let targetIndex = schema.versions.count - 1
        guard sourceIndex < targetIndex else {
            return
        }

        for step in sourceIndex..<targetIndex {
            try Self.migrateOneStep(
                storeAt: url,
                storeName: storeName,
                from: schema.versions[step],
                to: schema.versions[step + 1],
                step: step
            )
        }
    }

    private static func migrateOneStep(
        storeAt url: URL,
        storeName: String,
        from source: NSManagedObjectModel,
        to destination: NSManagedObjectModel,
        step: Int
    ) throws {
        guard let mapping = try? NSMappingModel.inferredMappingModel(
            forSourceModel: source,
            destinationModel: destination
        ) else {
            throw MigrationError.inferenceFailed(storeName: storeName, step: step)
        }

        let temporaryURL = url.deletingLastPathComponent()
            .appendingPathComponent("\(url.lastPathComponent).migrating")

        Self.removeStore(at: temporaryURL, model: destination)

        let manager = NSMigrationManager(sourceModel: source, destinationModel: destination)
        try manager.migrateStore(
            from: url,
            type: .sqlite,
            options: nil,
            mapping: mapping,
            to: temporaryURL,
            type: .sqlite,
            options: nil
        )

        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: destination)
        try coordinator.replacePersistentStore(
            at: url,
            withPersistentStoreFrom: temporaryURL,
            type: .sqlite
        )
        Self.removeStore(at: temporaryURL, model: destination)
    }

    private static func removeStore(at url: URL, model: NSManagedObjectModel) {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try? coordinator.destroyPersistentStore(at: url, type: .sqlite)

        for path in [url.path, url.path + "-shm", url.path + "-wal"] {
            try? FileManager.default.removeItem(atPath: path)
        }
    }
}
