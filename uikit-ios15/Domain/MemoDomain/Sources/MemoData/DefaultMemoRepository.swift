import CoreData
import Foundation

import BookModel
import MemoCore
import MemoModel
import PersistenceInterface

@objc(BookMemoEntity)
final class BookMemoEntity: NSManagedObject {
    static let entityName = "BookMemoEntity"

    @NSManaged var isbn: String
    @NSManaged var text: String
    @NSManaged var title: String
    @NSManaged var author: String?
    @NSManaged var publisher: String?
    @NSManaged var publishedAt: String?
    @NSManaged var coverURLString: String?
    @NSManaged var updatedAt: Date

    func fill(with book: Book, text: String, updatedAt: Date) {
        self.isbn = book.isbn
        self.text = text
        self.title = book.title
        self.author = book.author
        self.publisher = book.publisher
        self.publishedAt = book.publishedAt
        self.coverURLString = book.coverImageURL?.absoluteString
        self.updatedAt = updatedAt
    }

    var asDomain: BookMemo {
        BookMemo(
            book: Book(
                isbn: isbn,
                title: title,
                author: author,
                publisher: publisher,
                publishedAt: publishedAt,
                coverImageURL: coverURLString.flatMap(URL.init(string:))
            ),
            text: text,
            updatedAt: updatedAt
        )
    }
}

enum MemoObjectModel {
    static let schema = CoreDataSchema(versions: [v1(), v2()])

    private static func v1() -> NSManagedObjectModel {
        let entity = NSEntityDescription()
        entity.name = BookMemoEntity.entityName
        entity.managedObjectClassName = NSStringFromClass(BookMemoEntity.self)

        entity.properties = [
            Self.attribute("isbn", .stringAttributeType, isOptional: false),
            Self.attribute("text", .stringAttributeType, isOptional: false),
            Self.attribute("title", .stringAttributeType, isOptional: false),
            Self.attribute("author", .stringAttributeType),
            Self.attribute("publisher", .stringAttributeType),
            Self.attribute("publishedAt", .stringAttributeType),
            Self.attribute("coverURLString", .stringAttributeType),
            Self.attribute("updatedAt", .dateAttributeType, isOptional: false)
        ]

        let model = NSManagedObjectModel()
        model.entities = [entity]
        model.versionIdentifiers = ["1"]
        return model
    }

    private static func v2() -> NSManagedObjectModel {
        let entity = NSEntityDescription()
        entity.name = BookMemoEntity.entityName
        entity.managedObjectClassName = NSStringFromClass(BookMemoEntity.self)

        entity.properties = [
            Self.attribute("isbn", .stringAttributeType, isOptional: false),
            Self.attribute("text", .stringAttributeType, isOptional: false),
            Self.attribute("title", .stringAttributeType, isOptional: false),
            Self.attribute("author", .stringAttributeType),
            Self.attribute("publisher", .stringAttributeType),
            Self.attribute("publishedAt", .stringAttributeType),
            Self.attribute("coverURLString", .stringAttributeType),
            Self.attribute("updatedAt", .dateAttributeType, isOptional: false)
        ]

        entity.uniquenessConstraints = [["isbn"]]

        let model = NSManagedObjectModel()
        model.entities = [entity]
        model.versionIdentifiers = ["2"]
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

enum MemoRepositoryError: Error {
    case unexpectedEntityType
}

final class DefaultMemoRepository: MemoRepository {
    private let store: any CoreDataStore

    init(store: any CoreDataStore) {
        self.store = store
    }

    func list() async throws -> [BookMemo] {
        try await store.perform { context in
            try context.fetch(Self.request()).map(\.asDomain)
        }
    }

    func save(_ book: Book, text: String, updatedAt: Date) async throws {
        try await store.perform { context in
            let request = Self.request()
            request.predicate = NSPredicate(format: "isbn == %@", book.isbn)

            let record = try context.fetch(request).first
                ?? NSEntityDescription.insertNewObject(
                    forEntityName: BookMemoEntity.entityName,
                    into: context
                ) as? BookMemoEntity
            guard let record else { throw MemoRepositoryError.unexpectedEntityType }

            record.fill(with: book, text: text, updatedAt: updatedAt)
            try context.save()
        }
    }

    func remove(isbn: String) async throws {
        try await store.perform { context in
            let request = Self.request()
            request.predicate = NSPredicate(format: "isbn == %@", isbn)
            for target in try context.fetch(request) {
                context.delete(target)
            }
            try context.save()
        }
    }

    private static func request() -> NSFetchRequest<BookMemoEntity> {
        let request = NSFetchRequest<BookMemoEntity>(entityName: BookMemoEntity.entityName)
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        return request
    }
}

public func makeMemoRepository(storeFactory: CoreDataStoreFactory) -> any MemoRepository {
    DefaultMemoRepository(
        store: storeFactory.make("Memo", MemoObjectModel.schema)
    )
}
