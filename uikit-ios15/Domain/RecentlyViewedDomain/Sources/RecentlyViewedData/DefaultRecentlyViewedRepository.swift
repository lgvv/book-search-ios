import CoreData
import Foundation

import BookModel
import PersistenceInterface
import RecentlyViewedCore
import RecentlyViewedModel

@objc(RecentlyViewedBookEntity)
final class RecentlyViewedBookEntity: NSManagedObject {
    static let entityName = "RecentlyViewedBookEntity"

    @NSManaged var isbn: String
    @NSManaged var title: String
    @NSManaged var author: String?
    @NSManaged var publisher: String?
    @NSManaged var publishedAt: String?
    @NSManaged var coverURLString: String?
    @NSManaged var viewedAt: Date

    func fill(with book: Book, viewedAt: Date) {
        self.isbn = book.isbn
        self.title = book.title
        self.author = book.author
        self.publisher = book.publisher
        self.publishedAt = book.publishedAt
        self.coverURLString = book.coverImageURL?.absoluteString
        self.viewedAt = viewedAt
    }

    var asDomain: ViewedBook {
        ViewedBook(
            book: Book(
                isbn: self.isbn,
                title: self.title,
                author: self.author,
                publisher: self.publisher,
                publishedAt: self.publishedAt,
                coverImageURL: self.coverURLString.flatMap(URL.init(string:))
            ),
            viewedAt: self.viewedAt
        )
    }
}

enum RecentlyViewedObjectModel {
    static let schema = CoreDataSchema(v1())

    private static func v1() -> NSManagedObjectModel {
        let entity = NSEntityDescription()
        entity.name = RecentlyViewedBookEntity.entityName
        entity.managedObjectClassName = NSStringFromClass(RecentlyViewedBookEntity.self)

        entity.properties = [
            Self.attribute("isbn", .stringAttributeType, isOptional: false),
            Self.attribute("title", .stringAttributeType, isOptional: false),
            Self.attribute("author", .stringAttributeType),
            Self.attribute("publisher", .stringAttributeType),
            Self.attribute("publishedAt", .stringAttributeType),
            Self.attribute("coverURLString", .stringAttributeType),
            Self.attribute("viewedAt", .dateAttributeType, isOptional: false)
        ]
        entity.uniquenessConstraints = [["isbn"]]

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

final class DefaultRecentlyViewedRepository: RecentlyViewedRepository {
    private let store: any CoreDataStore

    init(store: any CoreDataStore) {
        self.store = store
    }

    func record(book: Book, keeping maxCount: Int) async throws {
        try await self.store.perform { context in
            let request = Self.request()
            request.predicate = NSPredicate(format: "isbn == %@", book.isbn)

            let record = try context.fetch(request).first
                ?? (NSEntityDescription.insertNewObject(
                    forEntityName: RecentlyViewedBookEntity.entityName,
                    into: context
                ) as? RecentlyViewedBookEntity)
            record?.fill(with: book, viewedAt: Date())

            let all = try context.fetch(Self.request())
            for stale in all.dropFirst(maxCount) {
                context.delete(stale)
            }

            try context.save()
        }
    }

    func list() async throws -> [ViewedBook] {
        try await self.store.perform { context in
            try context.fetch(Self.request()).map(\.asDomain)
        }
    }

    func remove(isbn: String) async throws {
        try await self.store.perform { context in
            let request = Self.request()
            request.predicate = NSPredicate(format: "isbn == %@", isbn)
            for target in try context.fetch(request) {
                context.delete(target)
            }
            try context.save()
        }
    }

    func clear() async throws {
        try await self.store.perform { context in
            for target in try context.fetch(Self.request()) {
                context.delete(target)
            }
            try context.save()
        }
    }

    private static func request() -> NSFetchRequest<RecentlyViewedBookEntity> {
        let request = NSFetchRequest<RecentlyViewedBookEntity>(
            entityName: RecentlyViewedBookEntity.entityName
        )
        request.sortDescriptors = [NSSortDescriptor(key: "viewedAt", ascending: false)]
        return request
    }
}

public func makeRecentlyViewedRepository(storeFactory: CoreDataStoreFactory) -> any RecentlyViewedRepository {
    DefaultRecentlyViewedRepository(
        store: storeFactory.make("RecentlyViewed", RecentlyViewedObjectModel.schema)
    )
}
