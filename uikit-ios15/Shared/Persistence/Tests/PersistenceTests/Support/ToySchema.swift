import CoreData
import Foundation

import PersistenceInterface

enum ToySchema {

    static let entityName = "Item"

    static func v1() -> NSManagedObjectModel {
        let entity = NSEntityDescription()
        entity.name = Self.entityName
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        entity.properties = [
            Self.attribute("id", .stringAttributeType, optional: false),
            Self.attribute("title", .stringAttributeType, optional: false),
        ]

        let model = NSManagedObjectModel()
        model.entities = [entity]
        model.versionIdentifiers = ["1"]
        return model
    }

    static func v2() -> NSManagedObjectModel {
        let entity = NSEntityDescription()
        entity.name = Self.entityName
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        entity.properties = [
            Self.attribute("id", .stringAttributeType, optional: false),
            Self.attribute("title", .stringAttributeType, optional: false),
            Self.attribute("note", .stringAttributeType, optional: true),
        ]

        let model = NSManagedObjectModel()
        model.entities = [entity]
        model.versionIdentifiers = ["2"]
        return model
    }

    static func unregisteredVersion() -> NSManagedObjectModel {
        let entity = NSEntityDescription()
        entity.name = Self.entityName
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        entity.properties = [
            Self.attribute("id", .stringAttributeType, optional: false),
            Self.attribute("otherValue", .integer64AttributeType, optional: false),
        ]

        let model = NSManagedObjectModel()
        model.entities = [entity]
        model.versionIdentifiers = ["unregistered"]
        return model
    }

    static func attribute(
        _ name: String,
        _ type: NSAttributeType,
        optional: Bool
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        return attribute
    }
}

extension ToySchema {

    static func withStore<T>(
        at url: URL,
        model: NSManagedObjectModel,
        _ block: (NSManagedObjectContext) throws -> T
    ) throws -> T {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let store = try coordinator.addPersistentStore(
            type: .sqlite,
            at: url
        )

        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator

        defer { try? coordinator.remove(store) }
        return try block(context)
    }

    static func insert(id: String, title: String, into context: NSManagedObjectContext) throws {
        let object = NSEntityDescription.insertNewObject(forEntityName: Self.entityName, into: context)
        object.setValue(id, forKey: "id")
        object.setValue(title, forKey: "title")
        try context.save()
    }

    static func fetchAll(from context: NSManagedObjectContext) throws -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: Self.entityName)
        request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        return try context.fetch(request)
    }

    static func fetchTitles(from context: NSManagedObjectContext) throws -> [String?] {
        try Self.fetchAll(from: context).map { $0.value(forKey: "title") as? String }
    }
}
