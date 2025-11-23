import Foundation
import Testing

import BookModel
import MemoModel
import SharedFoundation
import TestSupport

@testable import MemoCore

struct MemoServiceTests {

    private let pachinko = Book.fixture(isbn: "1", title: "파친코")
    private let toji = Book.fixture(isbn: "2", title: "토지")

    private var repository: StubMemoRepository!
    private var sut: DefaultMemoService!

    init() {
        self.repository = StubMemoRepository()
        self.sut = DefaultMemoService(repository: self.repository)
    }

    @Test
    func start이전에는_저장소를읽지않는다() async {
        let stayedIdle = await stayFalse({ [repository] in (repository?.listCallCount ?? 0) > 0 })

        #expect(stayedIdle)
    }

    @Test
    func start를부르면_저장소를읽어loaded로바꾼다() async {
        let memo = BookMemo(book: pachinko, text: "좋았다", updatedAt: Date())
        self.repository.listResult.withValue { $0 = .success([memo]) }
        let recorder = AsyncValueRecorder(self.sut.observe())

        await self.sut.start()

        #expect(recorder.last?.value == [memo])
    }

    @Test
    func 읽기가실패하면_failed를알린다() async {
        self.repository.listResult.withValue { $0 = .failure(.init(reason: "디스크")) }
        let recorder = AsyncValueRecorder(self.sut.observe())

        await self.sut.start()

        #expect(recorder.last == .failed)
    }

    @Test
    func 저장이성공하면_재조회를기다리지않고캐시에반영한다() async throws {
        await self.sut.start()
        self.repository.listResult.withValue { $0 = .failure(.init(reason: "디스크")) }
        let recorder = AsyncValueRecorder(self.sut.observe())

        try await self.sut.save(pachinko, text: "좋았다")

        let values = try await recorder.wait(untilCount: 2)
        #expect(values[1].value?.map(\.text) == ["좋았다"])
    }

    @Test
    func 저장한메모는_updatedAt내림차순으로정렬된다() async throws {
        let olderMemo = BookMemo(book: toji, text: "먼저", updatedAt: Date(timeIntervalSince1970: 0))
        self.repository.listResult.withValue { $0 = .success([olderMemo]) }
        await self.sut.start()
        self.repository.listResult.withValue { $0 = .failure(.init(reason: "디스크")) }
        let recorder = AsyncValueRecorder(self.sut.observe())

        try await self.sut.save(pachinko, text: "나중")

        let values = try await recorder.wait(untilCount: 2)
        #expect(values[1].value?.map(\.book.isbn) == [pachinko.isbn, toji.isbn])
    }

    @Test
    func 같은책에다시저장하면_항목이늘지않고내용만바뀐다() async throws {
        await self.sut.start()
        self.repository.listResult.withValue { $0 = .failure(.init(reason: "디스크")) }
        try await self.sut.save(pachinko, text: "처음")
        let recorder = AsyncValueRecorder(self.sut.observe())

        try await self.sut.save(pachinko, text: "고침")

        let values = try await recorder.wait(untilCount: 2)
        #expect(values[1].value?.map(\.text) == ["고침"])
    }

    @Test
    func 저장뒤재조회가실패해도_저장한내용이사라지지않는다() async throws {
        await self.sut.start()
        self.repository.listResult.withValue { $0 = .failure(.init(reason: "디스크")) }
        let recorder = AsyncValueRecorder(self.sut.observe())

        try await self.sut.save(pachinko, text: "좋았다")

        let values = try await recorder.wait(untilCount: 3)
        #expect(values.last?.value?.map(\.text) == ["좋았다"])
        #expect(values.last?.isStale == true)
    }

    @Test
    func 저장이실패하면_호출부에오류를전달한다() async {
        await self.sut.start()
        self.repository.saveResult.withValue { $0 = .failure(.init(reason: "디스크")) }

        do {
            try await self.sut.save(pachinko, text: "좋았다")
            Issue.record("실패해야 한다")
        } catch {
            #expect((error as? StubMemoRepository.Failure) == .init(reason: "디스크"))
        }
    }

    @Test
    func 빈텍스트로저장하면_메모를삭제한다() async throws {
        let memo = BookMemo(book: pachinko, text: "좋았다", updatedAt: Date())
        self.repository.listResult.withValue { $0 = .success([memo]) }
        await self.sut.start()

        try await self.sut.save(pachinko, text: "   ")

        #expect(self.repository.calls.value.contains(.remove(isbn: pachinko.isbn)))
    }

    @Test
    func 빈텍스트저장은_캐시에서도항목을뺀다() async throws {
        let memo = BookMemo(book: pachinko, text: "좋았다", updatedAt: Date())
        self.repository.listResult.withValue { $0 = .success([memo]) }
        await self.sut.start()
        self.repository.listResult.withValue { $0 = .failure(.init(reason: "디스크")) }
        let recorder = AsyncValueRecorder(self.sut.observe())

        try await self.sut.save(pachinko, text: "")

        let values = try await recorder.wait(untilCount: 2)
        #expect(values[1].value == [])
    }

    @Test
    func 읽기가한번도성공하지않았으면_빈저장을삭제로해석하지않는다() async {
        self.repository.listResult.withValue { $0 = .failure(.init(reason: "디스크")) }

        do {
            try await self.sut.save(pachinko, text: "")
            Issue.record("실패해야 한다")
        } catch {
            #expect(!(self.repository.calls.value.contains(.remove(isbn: pachinko.isbn))))
        }
    }

    @Test
    func 같은책의저장이겹치면_제출순서대로실행한다() async throws {
        await self.sut.start()
        let gate = self.repository.blockSaves()
        let service = self.sut!
        let book = self.pachinko

        async let first: Void = service.save(book, text: "첫번째")
        await gate.waitUntilArrived()
        async let second: Void = service.save(book, text: "두번째")

        gate.open()
        _ = try await (first, second)

        #expect(self.repository.calls.value.compactMap(\.savedText) == ["첫번째", "두번째"])
    }

    @Test
    func 다른책의저장은_서로를막지않는다() async throws {
        await self.sut.start()
        let gate = self.repository.blockSaves(for: pachinko.isbn)
        let service = self.sut!
        let book = self.pachinko

        async let blocked: Void = service.save(book, text: "멈춤")
        await gate.waitUntilArrived()

        try await self.sut.save(toji, text: "진행")

        #expect(self.repository.calls.value.contains { $0.savedText == "진행" })
        gate.open()
        try await blocked
    }

    @Test
    func 메모가있으면_found를돌려준다() async throws {
        let memo = BookMemo(book: pachinko, text: "좋았다", updatedAt: Date())
        self.repository.listResult.withValue { $0 = .success([memo]) }
        await self.sut.start()

        let lookup = try await self.sut.memo(pachinko.isbn)

        #expect(lookup == .found(memo))
    }

    @Test
    func 메모가없으면_notFound를돌려준다() async throws {
        await self.sut.start()

        let lookup = try await self.sut.memo(pachinko.isbn)

        #expect(lookup == .notFound)
    }

    @Test
    func 읽기가실패하면_조회가오류를던진다() async {
        self.repository.listResult.withValue { $0 = .failure(.init(reason: "디스크")) }

        do {
            _ = try await self.sut.memo(pachinko.isbn)
            Issue.record("실패해야 한다")
        } catch {
            #expect((error as? StubMemoRepository.Failure) == .init(reason: "디스크"))
        }
    }

    @Test
    func 로드된적없는상태의재시도는_처음부터다시읽는다() async {
        self.repository.listResult.withValue { $0 = .failure(.init(reason: "디스크")) }
        await self.sut.start()
        self.repository.listResult.withValue { $0 = .success([]) }

        await self.sut.reload()

        let recorder = AsyncValueRecorder(self.sut.observe())
        #expect(recorder.last?.value == [])
    }

    @Test
    func 이미로드된상태의재시도는_저장소를다시읽어수렴시킨다() async {
        await self.sut.start()
        let memo = BookMemo(book: pachinko, text: "다른 창에서 저장", updatedAt: Date())
        self.repository.listResult.withValue { $0 = .success([memo]) }

        await self.sut.reload()

        let recorder = AsyncValueRecorder(self.sut.observe())
        #expect(recorder.last?.value == [memo])
    }
}
