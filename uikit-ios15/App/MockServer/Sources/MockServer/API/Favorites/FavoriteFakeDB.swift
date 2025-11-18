import CoreData
import Foundation

import PersistenceInterface

@objc(MockFavoriteBookEntity)
final class MockFavoriteBookEntity: NSManagedObject {
    static let entityName = "FavoriteBookEntity"

    @NSManaged var isbn: String
    @NSManaged var title: String
    @NSManaged var author: String?
    @NSManaged var publisher: String?
    @NSManaged var publishedAt: String?
    @NSManaged var coverURLString: String?
    @NSManaged var createdAt: Date
}

extension MockFavoriteBookEntity {
    var record: FavoriteRecord {
        FavoriteRecord(
            isbn: self.isbn,
            title: self.title,
            author: self.author,
            publisher: self.publisher,
            publishedAt: self.publishedAt,
            coverImageURL: self.coverURLString,
            createdAt: self.createdAt
        )
    }

    func fill(with record: FavoriteRecord) {
        self.isbn = record.isbn
        self.title = record.title
        self.author = record.author
        self.publisher = record.publisher
        self.publishedAt = record.publishedAt
        self.coverURLString = record.coverImageURL
        self.createdAt = record.createdAt
    }
}

enum FavoriteFakeDB {
    static let storeName = "Favorite"

    static let schema = CoreDataSchema(versions: [v1()])

    private static func v1() -> NSManagedObjectModel {
        let entity = NSEntityDescription()
        entity.name = MockFavoriteBookEntity.entityName
        entity.managedObjectClassName = NSStringFromClass(MockFavoriteBookEntity.self)

        entity.properties = [
            Self.attribute("isbn", .stringAttributeType, isOptional: false),
            Self.attribute("title", .stringAttributeType, isOptional: false),
            Self.attribute("author", .stringAttributeType),
            Self.attribute("publisher", .stringAttributeType),
            Self.attribute("publishedAt", .stringAttributeType),
            Self.attribute("coverURLString", .stringAttributeType),
            Self.attribute("createdAt", .dateAttributeType, isOptional: false)
        ]

        let model = NSManagedObjectModel()
        model.entities = [entity]
        model.versionIdentifiers = ["1"]
        return model
    }

    private static func attribute(
        _ name: String,
        _ type: NSAttributeType,
        isOptional: Bool = true
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = isOptional
        return attribute
    }
}
