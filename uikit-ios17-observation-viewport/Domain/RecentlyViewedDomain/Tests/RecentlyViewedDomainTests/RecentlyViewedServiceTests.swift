import Foundation
import Testing

import BookModel
import RecentlyViewedModel
import SharedFoundation
import TestSupport

@testable import RecentlyViewedCore

struct RecentlyViewedServiceTests {

    private let pachinko = Book(isbn: "1", title: "파친코")
    private let toji = Book(isbn: "2", title: "토지")

    private var repository: StubRecentlyViewedRepository!
    private var sut: DefaultRecentlyViewedService!

    init() {
        self.repository = StubRecentlyViewedRepository()
        self.sut = DefaultRecentlyViewedService(repository: self.repository, maxCount: 20)
    }

    @Test
    func start이전에는_저장소를읽지않는다() async {
        let stayedIdle = await stayFalse({ [repository] in (repository?.listCallCount ?? 0) > 0 })

        #expect(stayedIdle)
    }

    @Test
    func start를부르면_저장소를읽어loaded로바꾼다() async {
        let viewed = ViewedBook(book: pachinko, viewedAt: Date())
        self.repository.listResult.withValue { $0 = .success([viewed]) }
        let recorder = AsyncValueRecorder(self.sut.observe())

        await self.sut.start()

        let didLoad = await waitUntil { recorder.last?.value == [viewed] }
        #expect(didLoad)
    }

    @Test
    func 처음부터읽기가실패하면_failed를알린다() async {
        self.repository.listResult.withValue { $0 = .failure(.init(reason: "디스크")) }
        let recorder = AsyncValueRecorder(self.sut.observe())

        await self.sut.start()

        let didFail = await waitUntil { recorder.last == .failed }
        #expect(didFail)
    }

    @Test
    func 기록하면_저장소에상한과함께넘긴다() async {
        await self.sut.start()

        await self.sut.record(pachinko)

        #expect(self.repository.calls.value.contains(.record(isbn: pachinko.isbn, maxCount: 20)))
    }

    @Test
    func 기록이성공하면_재조회를기다리지않고맨앞에넣는다() async throws {
        await self.sut.start()
        self.repository.listResult.withValue { $0 = .failure(.init(reason: "디스크")) }
        let recorder = AsyncValueRecorder(self.sut.observe())

        await self.sut.record(pachinko)

        let values = try await recorder.wait(untilCount: 2)
        #expect(values[1].value?.map(\.book.isbn) == [pachinko.isbn])
    }

    @Test
    func 이미본책을다시기록하면_중복없이맨앞으로올라온다() async throws {
        let older = ViewedBook(book: pachinko, viewedAt: Date(timeIntervalSince1970: 0))
        let otherBook = ViewedBook(book: toji, viewedAt: Date(timeIntervalSince1970: 100))
        self.repository.listResult.withValue { $0 = .success([otherBook, older]) }
        await self.sut.start()
        self.repository.listResult.withValue { $0 = .failure(.init(reason: "디스크")) }
        let recorder = AsyncValueRecorder(self.sut.observe())

        await self.sut.record(pachinko)

        let values = try await recorder.wait(untilCount: 2)
        #expect(values[1].value?.map(\.book.isbn) == [pachinko.isbn, toji.isbn])
    }

    @Test
    func 캐시반영도_상한을넘지않는다() async throws {
        let sut = DefaultRecentlyViewedService(repository: self.repository, maxCount: 2)
        self.repository.listResult.withValue {
            $0 = .success([
                ViewedBook(book: Book(isbn: "a", title: "a"), viewedAt: Date(timeIntervalSince1970: 200)),
                ViewedBook(book: Book(isbn: "b", title: "b"), viewedAt: Date(timeIntervalSince1970: 100)),
            ])
        }
        await sut.start()
        self.repository.listResult.withValue { $0 = .failure(.init(reason: "디스크")) }
        let recorder = AsyncValueRecorder(sut.observe())

        await sut.record(pachinko)

        let values = try await recorder.wait(untilCount: 2)
        #expect(values[1].value?.map(\.book.isbn) == [pachinko.isbn, "a"])
    }

    @Test
    func 기록이실패하면_캐시를건드리지않는다() async throws {
        let existing = ViewedBook(book: toji, viewedAt: Date())
        self.repository.listResult.withValue { $0 = .success([existing]) }
        await self.sut.start()
        self.repository.failWrites()
        let recorder = AsyncValueRecorder(self.sut.observe())

        await self.sut.record(pachinko)

        let values = try await recorder.wait(untilCount: 2)
        #expect(values.last?.value?.map(\.book.isbn) == [toji.isbn])
    }

    @Test
    func 한항목을삭제하면_캐시에서곧바로빠진다() async throws {
        self.repository.listResult.withValue {
            $0 = .success([
                ViewedBook(book: pachinko, viewedAt: Date()),
                ViewedBook(book: toji, viewedAt: Date()),
            ])
        }
        await self.sut.start()
        self.repository.listResult.withValue { $0 = .failure(.init(reason: "디스크")) }
        let recorder = AsyncValueRecorder(self.sut.observe())

        await self.sut.remove(isbn: pachinko.isbn)

        let values = try await recorder.wait(untilCount: 2)
        #expect(values[1].value?.map(\.book.isbn) == [toji.isbn])
    }

    @Test
    func 전체를지우면_캐시가곧바로비워진다() async throws {
        self.repository.listResult.withValue {
            $0 = .success([ViewedBook(book: pachinko, viewedAt: Date())])
        }
        await self.sut.start()
        self.repository.listResult.withValue { $0 = .failure(.init(reason: "디스크")) }
        let recorder = AsyncValueRecorder(self.sut.observe())

        await self.sut.clear()

        let values = try await recorder.wait(untilCount: 2)
        #expect(values[1].value == [])
    }

    @Test
    func 삭제가실패하면_캐시를건드리지않는다() async throws {
        let existing = ViewedBook(book: pachinko, viewedAt: Date())
        self.repository.listResult.withValue { $0 = .success([existing]) }
        await self.sut.start()
        self.repository.failWrites()
        let recorder = AsyncValueRecorder(self.sut.observe())

        await self.sut.remove(isbn: pachinko.isbn)

        let values = try await recorder.wait(untilCount: 2)
        #expect(values.last?.value?.map(\.book.isbn) == [pachinko.isbn])
    }

    @Test
    func 쓰기가겹치면_저장소가보는순서는제출순서다() async {
        await self.sut.start()
        let gate = self.repository.blockWrites()
        let service = self.sut!
        let book = self.pachinko

        async let first: Void = service.record(book)
        await gate.waitUntilArrived()
        async let second: Void = service.clear()

        gate.open()
        _ = await (first, second)

        let writes = self.repository.calls.value.filter { $0 != .list }
        #expect(writes == [.record(isbn: book.isbn, maxCount: 20), .clear])
    }

    @Test
    func 기록뒤재조회가실패해도_방금본책이사라지지않는다() async throws {
        await self.sut.start()
        self.repository.listResult.withValue { $0 = .failure(.init(reason: "디스크")) }
        let recorder = AsyncValueRecorder(self.sut.observe())

        await self.sut.record(pachinko)

        let values = try await recorder.wait(untilCount: 3)
        #expect(values.last?.value?.map(\.book.isbn) == [pachinko.isbn])
        #expect(values.last?.isStale == true)
    }

    @Test
    func 데이터가없는상태로다시시도하면_로딩회차를알린다() async throws {
        self.repository.listResult.withValue { $0 = .failure(.init(reason: "디스크")) }
        await self.sut.start()
        let recorder = AsyncValueRecorder(self.sut.observe())

        await self.sut.reload()

        let values = try await recorder.wait(untilCount: 3)
        #expect(values == [.failed, .loading, .failed])
    }

    @Test
    func 목록조회는_저장소를다시읽지않고캐시만본다() async {
        let viewed = ViewedBook(book: pachinko, viewedAt: Date())
        self.repository.listResult.withValue { $0 = .success([viewed]) }
        await self.sut.start()
        let callsAfterStart = self.repository.listCallCount

        let items = await self.sut.list()

        #expect(items == [viewed])
        #expect(self.repository.listCallCount == callsAfterStart)
    }
}
