import CoreData
import Foundation
import Testing

import PersistenceInterface

@testable import Persistence

final class CoreDataMigratorTests {

    private var directory: URL!
    private var storeURL: URL!

    init() throws {
        self.directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("migrator-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
        self.storeURL = self.directory.appendingPathComponent("Toy.sqlite")
    }

    deinit {
        try? FileManager.default.removeItem(at: self.directory)
    }

    @Test
    func 저장소파일이없으면_아무것도하지않는다() throws {
        let schema = CoreDataSchema(versions: [ToySchema.v1(), ToySchema.v2()])

        try CoreDataMigrator.migrateIfNeeded(storeAt: self.storeURL, storeName: "Toy", schema: schema)

        #expect(!(FileManager.default.fileExists(atPath: self.storeURL.path)))
    }

    @Test
    func 이미현재버전이면_저장소를건드리지않는다() throws {
        let v2 = ToySchema.v2()
        try ToySchema.withStore(at: self.storeURL, model: v2) { context in
            try ToySchema.insert(id: "1", title: "파친코", into: context)
        }
        let before = try Data(contentsOf: self.storeURL).count

        try CoreDataMigrator.migrateIfNeeded(
            storeAt: self.storeURL,
            storeName: "Toy",
            schema: CoreDataSchema(versions: [ToySchema.v1(), v2])
        )

        let rows = try ToySchema.withStore(at: self.storeURL, model: ToySchema.v2()) { context in
            try ToySchema.fetchAll(from: context)
        }
        #expect(rows.count == 1)
        #expect(try Data(contentsOf: self.storeURL).count == before)
    }

    @Test
    func 이전버전저장소를열면_현재버전으로이행하고데이터를보존한다() throws {
        try ToySchema.withStore(at: self.storeURL, model: ToySchema.v1()) { context in
            try ToySchema.insert(id: "1", title: "파친코", into: context)
            try ToySchema.insert(id: "2", title: "토지", into: context)
        }

        try CoreDataMigrator.migrateIfNeeded(
            storeAt: self.storeURL,
            storeName: "Toy",
            schema: CoreDataSchema(versions: [ToySchema.v1(), ToySchema.v2()])
        )

        let titles = try ToySchema.withStore(at: self.storeURL, model: ToySchema.v2()) { context in
            try ToySchema.fetchTitles(from: context)
        }
        #expect(titles == ["파친코", "토지"])
    }

    @Test
    func 이행후에는_새속성을읽고쓸수있다() throws {
        try ToySchema.withStore(at: self.storeURL, model: ToySchema.v1()) { context in
            try ToySchema.insert(id: "1", title: "파친코", into: context)
        }

        try CoreDataMigrator.migrateIfNeeded(
            storeAt: self.storeURL,
            storeName: "Toy",
            schema: CoreDataSchema(versions: [ToySchema.v1(), ToySchema.v2()])
        )

        let note = try ToySchema.withStore(at: self.storeURL, model: ToySchema.v2()) { context in
            let row = try #require(ToySchema.fetchAll(from: context).first)
            row.setValue("이행 후 기록", forKey: "note")
            try context.save()
            return row.value(forKey: "note") as? String
        }
        #expect(note == "이행 후 기록")
    }

    @Test
    func 두단계를건너뛰어야하면_한칸씩차례로이행한다() throws {
        let v3 = ToySchema.v2()
        v3.entities.first?.properties.append(
            ToySchema.attribute("extraValue", .integer64AttributeType, optional: true)
        )
        v3.versionIdentifiers = ["3"]

        try ToySchema.withStore(at: self.storeURL, model: ToySchema.v1()) { context in
            try ToySchema.insert(id: "1", title: "파친코", into: context)
        }

        try CoreDataMigrator.migrateIfNeeded(
            storeAt: self.storeURL,
            storeName: "Toy",
            schema: CoreDataSchema(versions: [ToySchema.v1(), ToySchema.v2(), v3])
        )

        let titles = try ToySchema.withStore(at: self.storeURL, model: v3) { context in
            try ToySchema.fetchTitles(from: context)
        }
        #expect(titles == ["파친코"])
    }

    @Test
    func 스키마역사에없는버전에서온저장소면_unknownSourceVersion으로실패한다() throws {
        try ToySchema.withStore(at: self.storeURL, model: ToySchema.unregisteredVersion()) { context in
            let object = NSEntityDescription.insertNewObject(
                forEntityName: ToySchema.entityName,
                into: context
            )
            object.setValue("1", forKey: "id")
            object.setValue(7, forKey: "otherValue")
            try context.save()
        }

        let error = #expect(throws: CoreDataMigrator.MigrationError.self) {
            try CoreDataMigrator.migrateIfNeeded(
                storeAt: self.storeURL,
                storeName: "Toy",
                schema: CoreDataSchema(versions: [ToySchema.v1(), ToySchema.v2()])
            )
        }
        guard case .unknownSourceVersion(let name) = error else {
            Issue.record("unknownSourceVersion이어야 한다: \(String(describing: error))")
            return
        }
        #expect(name == "Toy")
    }

    @Test
    func 앞선이행이중간에죽어잔여물이남아도_다시이행할수있다() throws {
        try ToySchema.withStore(at: self.storeURL, model: ToySchema.v1()) { context in
            try ToySchema.insert(id: "1", title: "파친코", into: context)
        }
        let leftover = self.storeURL.appendingPathExtension("migrating")
        try ToySchema.withStore(at: leftover, model: ToySchema.v2()) { context in
            try ToySchema.insert(id: "쓰레기", title: "앞선 시도의 잔여물", into: context)
        }

        try CoreDataMigrator.migrateIfNeeded(
            storeAt: self.storeURL,
            storeName: "Toy",
            schema: CoreDataSchema(versions: [ToySchema.v1(), ToySchema.v2()])
        )

        let titles = try ToySchema.withStore(at: self.storeURL, model: ToySchema.v2()) { context in
            try ToySchema.fetchTitles(from: context)
        }
        #expect(titles == ["파친코"])
        #expect(!(FileManager.default.fileExists(atPath: leftover.path)))
    }
}
