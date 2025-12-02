import CoreData
import Foundation
import Testing

import PersistenceInterface

@testable import Persistence

struct CoreDataStoreFactoryTests {

    @Test
    func inMemory저장소는_읽고쓸수있다() async throws {
        let sut = CoreDataStoreFactory.inMemory.make("Toy", CoreDataSchema(ToySchema.v1()))

        try await sut.perform { context in
            try ToySchema.insert(id: "1", title: "파친코", into: context)
        }

        let titles = try await sut.perform { context in
            try ToySchema.fetchAll(from: context).map { $0.value(forKey: "title") as? String }
        }
        #expect(titles == ["파친코"])
    }

    @Test
    func inMemory저장소를새로만들면_이전내용이없다() async throws {
        let first = CoreDataStoreFactory.inMemory.make("Toy", CoreDataSchema(ToySchema.v1()))
        try await first.perform { context in
            try ToySchema.insert(id: "1", title: "파친코", into: context)
        }

        let second = CoreDataStoreFactory.inMemory.make("Toy", CoreDataSchema(ToySchema.v1()))

        let count = try await second.perform { context in
            try ToySchema.fetchAll(from: context).count
        }
        #expect(count == 0)
    }

    @Test
    func perform이던지면_그오류가호출부로전달된다() async {
        let sut = CoreDataStoreFactory.inMemory.make("Toy", CoreDataSchema(ToySchema.v1()))
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
        let sut = CoreDataStoreFactory.inMemory.make("Toy", CoreDataSchema(ToySchema.v1()))

        await withTaskGroup(of: Void.self) { group in
            for index in 0 ..< 30 {
                group.addTask {
                    try? await sut.perform { context in
                        try ToySchema.insert(id: "\(index)", title: "책\(index)", into: context)
                    }
                }
            }
        }

        let count = try await sut.perform { context in
            try ToySchema.fetchAll(from: context).count
        }
        #expect(count == 30)
    }
}

struct CoreDataSchemaTests {

    @Test
    func 현재버전은_역사의마지막이다() {
        let v1 = ToySchema.v1()
        let v2 = ToySchema.v2()

        let sut = CoreDataSchema(versions: [v1, v2])

        #expect(sut.current.versionIdentifiers == v2.versionIdentifiers)
        #expect(sut.versions.count == 2)
    }

    @Test
    func 버전이하나뿐인편의이니셜라이저도_같은결과를만든다() {
        let only = ToySchema.v1()

        let sut = CoreDataSchema(only)

        #expect(sut.versions.count == 1)
        #expect(sut.current.versionIdentifiers == only.versionIdentifiers)
    }
}
