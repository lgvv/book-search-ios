import Foundation
import SwiftData

import PersistenceInterface

enum FavoriteSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] { [FavoriteRecordModel.self] }

    @Model
    final class FavoriteRecordModel {
        #Unique<FavoriteRecordModel>([\.isbn])

        #Index<FavoriteRecordModel>([\.createdAt])

        var isbn: String
        var title: String
        var author: String?
        var publisher: String?
        var publishedAt: String?
        var coverURLString: String?
        var createdAt: Date

        init(record: FavoriteRecord) {
            self.isbn = record.isbn
            self.title = record.title
            self.author = record.author
            self.publisher = record.publisher
            self.publishedAt = record.publishedAt
            self.coverURLString = record.coverImageURL
            self.createdAt = record.createdAt
        }
    }
}

typealias FavoriteRecordModel = FavoriteSchemaV1.FavoriteRecordModel

enum FavoriteMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [FavoriteSchemaV1.self] }

    static var stages: [MigrationStage] { [] }
}

extension FavoriteRecordModel {
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
}

enum FavoriteFakeDB {
    static let storeName = "Favorite"
}
