import CoreData
import Foundation

import PersistenceInterface

struct FavoriteRecordStore: Sendable {
    private let store: any CoreDataStore

    init(store: any CoreDataStore) {
        self.store = store
    }

    func all() async throws -> [FavoriteRecord] {
        try await self.store.perform { context in
            try context.fetch(Self.fetchRequest()).map(\.record)
        }
    }

    func insertIfAbsent(_ record: FavoriteRecord) async throws -> FavoriteRecord? {
        try await self.store.perform { context in
            let request = Self.fetchRequest()
            request.predicate = NSPredicate(format: "isbn == %@", record.isbn)
            guard try context.count(for: request) == 0 else { return nil }

            guard let object = NSEntityDescription.insertNewObject(
                forEntityName: MockFavoriteBookEntity.entityName,
                into: context
            ) as? MockFavoriteBookEntity else {
                throw FavoriteStoreError.entityClassMismatch
            }

            object.fill(with: record)
            try context.save()
            return object.record
        }
    }

    func delete(isbn: String) async throws -> Bool {
        try await self.store.perform { context in
            let request = Self.fetchRequest()
            request.predicate = NSPredicate(format: "isbn == %@", isbn)

            let targets = try context.fetch(request)
            guard !targets.isEmpty else { return false }

            for target in targets {
                context.delete(target)
            }
            try context.save()
            return true
        }
    }

    private static func fetchRequest() -> NSFetchRequest<MockFavoriteBookEntity> {
        let request = NSFetchRequest<MockFavoriteBookEntity>(entityName: MockFavoriteBookEntity.entityName)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return request
    }
}

enum FavoriteStoreError: Error {
    case entityClassMismatch
}

struct FavoriteRecord: Sendable {
    let isbn: String
    let title: String
    let author: String?
    let publisher: String?
    let publishedAt: String?
    let coverImageURL: String?
    let createdAt: Date
}
