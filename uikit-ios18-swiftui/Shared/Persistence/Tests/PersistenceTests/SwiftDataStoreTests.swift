import Foundation
import SwiftData
import Testing

import PersistenceInterface

@testable import Persistence

struct SwiftDataStoreFactoryTests {

    @Test
    func inMemory저장소는_읽고쓸수있다() async throws {
        let sut = SwiftDataStoreFactory.inMemory.make("Toy", ToyMigrationPlan.self)

        try await sut.perform { context in
            context.insert(ToyBook(id: "1", title: "파친코"))
            try context.save()
        }

        let titles = try await sut.perform { context in
            try context.fetch(FetchDescriptor<ToyBook>()).map(\.title)
        }
        #expect(titles == ["파친코"])
    }

    @Test
    func inMemory저장소를새로만들면_이전내용이없다() async throws {
        let first = SwiftDataStoreFactory.inMemory.make("Toy", ToyMigrationPlan.self)
        try await first.perform { context in
            context.insert(ToyBook(id: "1", title: "파친코"))
            try context.save()
        }

        let second = SwiftDataStoreFactory.inMemory.make("Toy", ToyMigrationPlan.self)

        let count = try await second.perform { context in
            try context.fetchCount(FetchDescriptor<ToyBook>())
        }
        #expect(count == 0)
    }

    @Test
    func perform이던지면_그오류가호출부로전달된다() async {
        let sut = SwiftDataStoreFactory.inMemory.make("Toy", ToyMigrationPlan.self)
        struct Boom: Error {}

        do {
            try await sut.perform { _ -> Int in throw Boom() }
            Issue.record("오류가 전달되어야 한다")
        } catch {
            #expect(error is Boom)
        }
    }

    @Test
    func 동시에perform을불러도_모두완료된다() async throws {
        let sut = SwiftDataStoreFactory.inMemory.make("Toy", ToyMigrationPlan.self)

        await withTaskGroup(of: Void.self) { group in
            for index in 0 ..< 30 {
                group.addTask {
                    try? await sut.perform { context in
                        context.insert(ToyBook(id: "\(index)", title: "책\(index)"))
                        try context.save()
                    }
                }
            }
        }

        let count = try await sut.perform { context in
            try context.fetchCount(FetchDescriptor<ToyBook>())
        }
        #expect(count == 30)
    }
}

struct SchemaMigrationPlanTests {

    @Test
    func 현재스키마는_계획의마지막버전이다() {
        let sut = ToyTwoVersionMigrationPlan.currentSchema

        #expect(sut.version == ToySchemaV2.versionIdentifier)
    }

    @Test
    func 버전이하나뿐인계획도_그버전을현재스키마로준다() {
        let sut = ToyMigrationPlan.currentSchema

        #expect(sut.version == ToySchemaV1.versionIdentifier)
    }
}
