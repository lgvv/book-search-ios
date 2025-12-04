import Foundation
import SwiftData

import PersistenceInterface

extension SwiftDataStoreFactory {
    public static let live = Self { name, migrationPlan in
        Self.makeStore(
            name: name,
            migrationPlan: migrationPlan,
            configuration: ModelConfiguration(
                name,
                schema: migrationPlan.currentSchema,
                url: Self.storeURL(for: name)
            )
        )
    }

    public static let inMemory = Self { name, migrationPlan in
        Self.makeStore(
            name: name,
            migrationPlan: migrationPlan,
            configuration: ModelConfiguration(
                name,
                schema: migrationPlan.currentSchema,
                isStoredInMemoryOnly: true
            )
        )
    }

    private static func storeURL(for name: String) -> URL {
        do {
            let directory = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            return directory.appendingPathComponent("\(name).store")
        } catch {
            fatalError("SwiftData 저장소 디렉터리를 만들 수 없다(\(name)): \(error)")
        }
    }

    private static func makeStore(
        name: String,
        migrationPlan: any SchemaMigrationPlan.Type,
        configuration: ModelConfiguration
    ) -> any SwiftDataStore {
        do {
            let container = try ModelContainer(
                for: migrationPlan.currentSchema,
                migrationPlan: migrationPlan,
                configurations: [configuration]
            )
            return DefaultSwiftDataStore(modelContainer: container)
        } catch {
            fatalError("SwiftData store 로드 실패(\(name)): \(error)")
        }
    }
}
