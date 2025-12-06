import Foundation
import SwiftData

import PersistenceInterface

struct FavoriteRecordStore: Sendable {
    private let store: any SwiftDataStore

    init(store: any SwiftDataStore) {
        self.store = store
    }

    func all() async throws -> [FavoriteRecord] {
        try await self.store.perform { context in
            try context.fetch(Self.descriptor()).map(\.record)
        }
    }

    func insertIfAbsent(_ record: FavoriteRecord) async throws -> FavoriteRecord? {
        try await self.store.perform { context in
            let isbn = record.isbn
            var existing = FetchDescriptor<FavoriteRecordModel>(
                predicate: #Predicate { $0.isbn == isbn }
            )
            existing.fetchLimit = 1
            guard try context.fetchCount(existing) == 0 else { return nil }

            let model = FavoriteRecordModel(record: record)
            context.insert(model)
            try context.save()
            return model.record
        }
    }

    func delete(isbn: String) async throws -> Bool {
        try await self.store.perform { context in
            var descriptor = FetchDescriptor<FavoriteRecordModel>(
                predicate: #Predicate { $0.isbn == isbn }
            )
            descriptor.fetchLimit = 1

            let targets = try context.fetch(descriptor)
            guard !targets.isEmpty else { return false }

            for target in targets {
                context.delete(target)
            }
            try context.save()
            return true
        }
    }

    private static func descriptor() -> FetchDescriptor<FavoriteRecordModel> {
        FetchDescriptor<FavoriteRecordModel>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
    }
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
