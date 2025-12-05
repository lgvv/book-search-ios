import Foundation
import SwiftData

enum ToySchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] { [ToyBook.self] }

    @Model
    final class ToyBook {
        #Unique<ToyBook>([\.id])

        var id: String
        var title: String

        init(id: String, title: String) {
            self.id = id
            self.title = title
        }
    }
}

typealias ToyBook = ToySchemaV1.ToyBook

enum ToySchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }

    static var models: [any PersistentModel.Type] { [ToyBook.self] }

    @Model
    final class ToyBook {
        #Unique<ToyBook>([\.id])

        var id: String
        var title: String
        var author: String?

        init(id: String, title: String, author: String? = nil) {
            self.id = id
            self.title = title
            self.author = author
        }
    }
}

enum ToyMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [ToySchemaV1.self] }

    static var stages: [MigrationStage] { [] }
}

enum ToyTwoVersionMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [ToySchemaV1.self, ToySchemaV2.self] }

    static var stages: [MigrationStage] {
        [.lightweight(fromVersion: ToySchemaV1.self, toVersion: ToySchemaV2.self)]
    }
}
