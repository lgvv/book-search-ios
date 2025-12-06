import Foundation
import SwiftData

import BookModel
import MemoCore
import MemoModel
import PersistenceInterface

enum MemoSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] { [BookMemoRecord.self] }

    @Model
    final class BookMemoRecord {
        #Unique<BookMemoRecord>([\.isbn])

        #Index<BookMemoRecord>([\.updatedAt])

        var isbn: String
        var text: String
        var title: String
        var author: String?
        var publisher: String?
        var publishedAt: String?
        var coverURLString: String?
        var updatedAt: Date

        init(book: Book, text: String, updatedAt: Date) {
            self.isbn = book.isbn
            self.text = text
            self.title = book.title
            self.author = book.author
            self.publisher = book.publisher
            self.publishedAt = book.publishedAt
            self.coverURLString = book.coverImageURL?.absoluteString
            self.updatedAt = updatedAt
        }
    }
}

typealias BookMemoRecord = MemoSchemaV1.BookMemoRecord

enum MemoMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [MemoSchemaV1.self] }

    static var stages: [MigrationStage] { [] }
}

extension BookMemoRecord {
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
                isbn: self.isbn,
                title: self.title,
                author: self.author,
                publisher: self.publisher,
                publishedAt: self.publishedAt,
                coverImageURL: self.coverURLString.flatMap(URL.init(string:))
            ),
            text: self.text,
            updatedAt: self.updatedAt
        )
    }
}

final class DefaultMemoRepository: MemoRepository {
    private let store: any SwiftDataStore

    init(store: any SwiftDataStore) {
        self.store = store
    }

    func list() async throws -> [BookMemo] {
        try await self.store.perform { context in
            try context.fetch(Self.descriptor()).map(\.asDomain)
        }
    }

    func save(_ book: Book, text: String, updatedAt: Date) async throws {
        try await self.store.perform { context in
            let isbn = book.isbn
            var descriptor = FetchDescriptor<BookMemoRecord>(
                predicate: #Predicate { $0.isbn == isbn }
            )
            descriptor.fetchLimit = 1

            if let existing = try context.fetch(descriptor).first {
                existing.fill(with: book, text: text, updatedAt: updatedAt)
            } else {
                context.insert(BookMemoRecord(book: book, text: text, updatedAt: updatedAt))
            }

            try context.save()
        }
    }

    func remove(isbn: String) async throws {
        try await self.store.perform { context in
            try context.delete(model: BookMemoRecord.self, where: #Predicate { $0.isbn == isbn })
            try context.save()
        }
    }

    private static func descriptor() -> FetchDescriptor<BookMemoRecord> {
        FetchDescriptor<BookMemoRecord>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
    }
}

public func makeMemoRepository(storeFactory: SwiftDataStoreFactory) -> any MemoRepository {
    DefaultMemoRepository(
        store: storeFactory.make("Memo", MemoMigrationPlan.self)
    )
}
