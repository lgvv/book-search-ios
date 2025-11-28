import Foundation
import Testing

import BookModel
import SharedFoundation
import TestSupport

@testable import FavoriteCore

struct FavoriteServiceTests {

    private let pachinko = Book.fixture(isbn: "1", title: "파친코")
    private let toji = Book.fixture(isbn: "2", title: "토지")

    private var repository: StubFavoriteRepository!
    private var sut: DefaultFavoriteService!

    init() {
        self.repository = StubFavoriteRepository()
        self.sut = DefaultFavoriteService(repository: self.repository)
    }

    @Test
    func start이전에는_저장소를읽지않는다() async {
        let stayedIdle = await stayFalse({ [repository] in repository?.listCallCount ?? 0 > 0 })

        #expect(stayedIdle)
    }

    @Test
    func start를부르면_저장소를읽어loaded로바꾼다() async {
        self.repository.listResult.withValue { $0 = .success([pachinko]) }
        let recorder = AsyncValueRecorder(self.sut.observe())

        await self.sut.start()

        let didLoad = await waitUntil { recorder.last?.value == [pachinko] }
        #expect(didLoad)
        #expect(self.repository.listCallCount == 1)
    }

    @Test
    func 구독을시작하면_현재상태를곧바로받는다() async {
        await self.sut.start()

        let recorder = AsyncValueRecorder(self.sut.observe())

        let values = try? await recorder.wait(untilCount: 1)
        #expect(values == [.loaded([])])
    }

    @Test
    func 추가가성공하면_재조회를기다리지않고캐시에반영한다() async {
        await self.sut.start()
        let recorder = AsyncValueRecorder(self.sut.observe())

        await self.sut.add(pachinko)

        let values = try? await recorder.wait(untilCount: 2)
        #expect((values?[1].value) == [pachinko])
    }

    @Test
    func 추가가성공한뒤재조회가실패해도_방금한조작이사라지지않는다() async {
        await self.sut.start()
        self.repository.listResult.withValue { $0 = .failure(.init(reason: "네트워크")) }
        let recorder = AsyncValueRecorder(self.sut.observe())

        await self.sut.add(pachinko)

        let values = try? await recorder.wait(untilCount: 3)
        #expect(values?.last?.value == [pachinko])
        #expect(values?.last?.isStale == true)
    }

    @Test
    func 제거가성공하면_캐시에서곧바로빠진다() async {
        self.repository.listResult.withValue { $0 = .success([pachinko, toji]) }
        await self.sut.start()
        self.repository.listResult.withValue { $0 = .failure(.init(reason: "네트워크")) }
        let recorder = AsyncValueRecorder(self.sut.observe())

        await self.sut.remove(isbn: pachinko.isbn)

        let values = try? await recorder.wait(untilCount: 2)
        #expect((values?[1].value) == [toji])
    }

    @Test
    func 추가한책은_목록맨앞에놓인다() async {
        self.repository.listResult.withValue { $0 = .success([toji]) }
        await self.sut.start()
        self.repository.listResult.withValue { $0 = .failure(.init(reason: "네트워크")) }
        let recorder = AsyncValueRecorder(self.sut.observe())

        await self.sut.add(pachinko)

        let values = try? await recorder.wait(untilCount: 2)
        #expect((values?[1].value?.map(\.isbn)) == [pachinko.isbn, toji.isbn])
    }

    @Test
    func 쓰기가실패하면_캐시를건드리지않는다() async {
        self.repository.listResult.withValue { $0 = .success([toji]) }
        await self.sut.start()
        self.repository.failAllWrites()
        let recorder = AsyncValueRecorder(self.sut.observe())

        await self.sut.add(pachinko)

        let values = try? await recorder.wait(untilCount: 2)
        #expect(values?.last?.value == [toji])
    }

    @Test
    func 처음부터읽기가실패하면_failed를알린다() async {
        self.repository.listResult.withValue { $0 = .failure(.init(reason: "네트워크")) }
        let recorder = AsyncValueRecorder(self.sut.observe())

        await self.sut.start()

        let didFail = await waitUntil { recorder.last == .failed }
        #expect(didFail)
    }

    @Test
    func 데이터가없는상태로다시시도하면_로딩회차를알린다() async {
        self.repository.listResult.withValue { $0 = .failure(.init(reason: "네트워크")) }
        await self.sut.start()
        let recorder = AsyncValueRecorder(self.sut.observe())

        await self.sut.reload()

        let values = try? await recorder.wait(untilCount: 3)
        #expect((values?[0]) == .failed)
        #expect((values?[1]) == .loading)
        #expect((values?[2]) == .failed)
    }

    @Test
    func 재시도가성공하면_failed에서loaded로돌아온다() async {
        self.repository.listResult.withValue { $0 = .failure(.init(reason: "네트워크")) }
        await self.sut.start()
        self.repository.listResult.withValue { $0 = .success([pachinko]) }

        await self.sut.reload()

        let recorder = AsyncValueRecorder(self.sut.observe())
        let values = try? await recorder.wait(untilCount: 1)
        #expect(values?.last?.value == [pachinko])
        #expect(values?.last?.isStale == false)
    }

    @Test
    func 목록조회는_저장소를다시읽지않고캐시만본다() async {
        self.repository.listResult.withValue { $0 = .success([pachinko, toji]) }
        await self.sut.start()
        let callsAfterStart = self.repository.listCallCount

        let books = await self.sut.list()

        #expect(books == [pachinko, toji])
        #expect(self.repository.listCallCount == callsAfterStart)
    }

    @Test
    func 즐겨찾기여부는_캐시에있는지로판단한다() async {
        self.repository.listResult.withValue { $0 = .success([pachinko]) }
        await self.sut.start()

        let isPachinko = await self.sut.isFavorite(pachinko.isbn)
        let isToji = await self.sut.isFavorite(toji.isbn)
        #expect(isPachinko)
        #expect(!(isToji))
    }

    @Test
    func 읽기전에는_목록이비어있다() async {
        let books = await self.sut.list()

        #expect(books == [])
    }

    @Test
    func 실패스트림은_구독전에일어난실패를뒤늦게주지않는다() async {
        await self.sut.start()
        self.repository.failAllWrites()

        let early = AsyncValueRecorder(self.sut.observeFailures())
        await self.sut.add(pachinko)
        let published = try? await early.wait(untilCount: 1)
        #expect(published?.count == 1)

        let late = AsyncValueRecorder(self.sut.observeFailures())

        let stayedSilent = await stayFalse({ !late.values.isEmpty }, for: 0.1)
        #expect(stayedSilent)
    }
}
