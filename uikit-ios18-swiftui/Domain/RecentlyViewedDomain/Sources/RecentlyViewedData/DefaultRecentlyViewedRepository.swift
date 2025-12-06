import Foundation
import SwiftData

import BookModel
import PersistenceInterface
import RecentlyViewedCore
import RecentlyViewedModel

enum RecentlyViewedSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] { [RecentlyViewedBookRecord.self] }

    @Model
    final class RecentlyViewedBookRecord {
        #Unique<RecentlyViewedBookRecord>([\.isbn])

        #Index<RecentlyViewedBookRecord>([\.viewedAt])

        var isbn: String
        var title: String
        var author: String?
        var publisher: String?
        var publishedAt: String?
        var coverURLString: String?
        var viewedAt: Date

        init(book: Book, viewedAt: Date) {
            self.isbn = book.isbn
            self.title = book.title
            self.author = book.author
            self.publisher = book.publisher
            self.publishedAt = book.publishedAt
            self.coverURLString = book.coverImageURL?.absoluteString
            self.viewedAt = viewedAt
        }
    }
}

typealias RecentlyViewedBookRecord = RecentlyViewedSchemaV1.RecentlyViewedBookRecord

enum RecentlyViewedMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [RecentlyViewedSchemaV1.self] }

    static var stages: [MigrationStage] { [] }
}

extension RecentlyViewedBookRecord {
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

final class DefaultRecentlyViewedRepository: RecentlyViewedRepository {
    private let store: any SwiftDataStore

    init(store: any SwiftDataStore) {
        self.store = store
    }

    func record(book: Book, keeping maxCount: Int) async throws {
        try await self.store.perform { context in
            let isbn = book.isbn
            var descriptor = FetchDescriptor<RecentlyViewedBookRecord>(
                predicate: #Predicate { $0.isbn == isbn }
            )
            descriptor.fetchLimit = 1

            if let existing = try context.fetch(descriptor).first {
                existing.fill(with: book, viewedAt: Date())
            } else {
                context.insert(RecentlyViewedBookRecord(book: book, viewedAt: Date()))
            }

            let all = try context.fetch(Self.descriptor())
            for stale in all.dropFirst(maxCount) {
                context.delete(stale)
            }

            try context.save()
        }
    }

    func list() async throws -> [ViewedBook] {
        try await self.store.perform { context in
            try context.fetch(Self.descriptor()).map(\.asDomain)
        }
    }

    func remove(isbn: String) async throws {
        try await self.store.perform { context in
            try context.delete(
                model: RecentlyViewedBookRecord.self,
                where: #Predicate { $0.isbn == isbn }
            )
            try context.save()
        }
    }

    func clear() async throws {
        try await self.store.perform { context in
            try context.delete(model: RecentlyViewedBookRecord.self)
            try context.save()
        }
    }

    private static func descriptor() -> FetchDescriptor<RecentlyViewedBookRecord> {
        FetchDescriptor<RecentlyViewedBookRecord>(
            sortBy: [SortDescriptor(\.viewedAt, order: .reverse)]
        )
    }
}

public func makeRecentlyViewedRepository(
    storeFactory: SwiftDataStoreFactory
) -> any RecentlyViewedRepository {
    DefaultRecentlyViewedRepository(
        store: storeFactory.make("RecentlyViewed", RecentlyViewedMigrationPlan.self)
    )
}
