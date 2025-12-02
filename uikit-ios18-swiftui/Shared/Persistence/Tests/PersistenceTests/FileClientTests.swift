import Foundation
import Testing

import PersistenceInterface

@testable import Persistence

final class FileClientTests {

    private var directoryName: String!
    private var sut: FileClient!

    init() {
        self.directoryName = "book-search-tests-\(UUID().uuidString)"
        self.sut = .caches(directoryName: self.directoryName)
    }

    deinit {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        try? FileManager.default.removeItem(at: caches.appendingPathComponent(self.directoryName))
        self.sut = nil
    }

    @Test
    func 저장한데이터를_같은키로읽을수있다() throws {
        let data = Data("이미지 바이트".utf8)

        try self.sut.setData(data, "abc.1")

        #expect(self.sut.data("abc.1") == data)
    }

    @Test
    func 저장한적없는키는_nil이다() {
        #expect(self.sut.data("없는키") == nil)
    }

    @Test
    func 같은키에다시쓰면_새내용으로덮어쓴다() throws {
        try self.sut.setData(Data("이전".utf8), "abc.1")

        try self.sut.setData(Data("이후".utf8), "abc.1")

        #expect(self.sut.data("abc.1") == Data("이후".utf8))
    }

    @Test
    func 저장한키들을_모두열거한다() throws {
        try self.sut.setData(Data("1".utf8), "a.1")
        try self.sut.setData(Data("2".utf8), "b.1")
        try self.sut.setData(Data("3".utf8), "c.2")

        let keys = try self.sut.keys()

        #expect(Set(keys) == ["a.1", "b.1", "c.2"])
    }

    @Test
    func 비어있는저장소의키목록은_빈배열이다() throws {
        let keys = try self.sut.keys()

        #expect(keys == [])
    }

    @Test
    func 제거하면_읽을수없고목록에서도빠진다() throws {
        try self.sut.setData(Data("1".utf8), "a.1")

        try self.sut.remove("a.1")

        #expect(self.sut.data("a.1") == nil)
        #expect(try self.sut.keys() == [])
    }

    @Test
    func 이미없는파일을제거해도_던지지않는다() throws {
        #expect(throws: Never.self) { try self.sut.remove("없는키") }
    }

    @Test
    func 다른디렉터리의클라이언트는_서로의파일을보지못한다() throws {
        let otherName = "book-search-tests-\(UUID().uuidString)"
        let other = FileClient.caches(directoryName: otherName)
        defer {
            let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            try? FileManager.default.removeItem(at: caches.appendingPathComponent(otherName))
        }

        try self.sut.setData(Data("이쪽".utf8), "a.1")

        #expect(other.data("a.1") == nil)
        #expect(try other.keys() == [])
    }
}
