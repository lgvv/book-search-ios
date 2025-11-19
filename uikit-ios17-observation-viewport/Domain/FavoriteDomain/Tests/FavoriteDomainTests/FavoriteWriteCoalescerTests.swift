import XCTest

import BookModel
import SharedFoundation
import TestSupport

@testable import FavoriteCore

final class FavoriteWriteCoalescerTests: XCTestCase {

    private let pachinko = Book.fixture(isbn: "1", title: "파친코")
    private let toji = Book.fixture(isbn: "2", title: "토지")

    private var repository: StubFavoriteRepository!
    private var sut: DefaultFavoriteService!

    override func setUp() {
        super.setUp()
        self.repository = StubFavoriteRepository()
        self.sut = DefaultFavoriteService(repository: self.repository)
    }

    private func completeInitialLoad() async {
        await self.sut.start()
    }

    func test_쓰기가진행중일때들어온제출은_저장소로곧장나가지않는다() async {
        await self.completeInitialLoad()
        let gate = self.repository.blockWrites(for: pachinko.isbn)

        await self.sut.add(pachinko)
        await gate.waitUntilArrived()
        await self.sut.remove(isbn: pachinko.isbn)
        await self.sut.add(pachinko)

        XCTAssertEqual(self.repository.writeCalls, [.add(isbn: pachinko.isbn)])
        gate.open()
    }

    func test_연타로세번제출하면_진행중1건과최종값1건만저장소로나간다() async {
        await self.completeInitialLoad()
        let gate = self.repository.blockWrites(for: pachinko.isbn)

        await self.sut.add(pachinko)
        await gate.waitUntilArrived()
        await self.sut.remove(isbn: pachinko.isbn)
        await self.sut.add(pachinko)
        await self.sut.remove(isbn: pachinko.isbn)

        gate.open()

        let didSettle = await waitUntil { [repository] in repository?.writeCalls.count == 2 }
        XCTAssertTrue(didSettle)
        XCTAssertEqual(
            self.repository.writeCalls,
            [.add(isbn: pachinko.isbn), .remove(isbn: pachinko.isbn)]
        )
    }

    func test_진행중쓰기가성공하고대기분의목표가같으면_대기분을생략한다() async {
        await self.completeInitialLoad()
        let gate = self.repository.blockWrites(for: pachinko.isbn)

        await self.sut.add(pachinko)
        await gate.waitUntilArrived()
        await self.sut.add(pachinko)

        gate.open()

        let didStayOne = await stayFalse(
            { [repository] in (repository?.writeCalls.count ?? 0) > 1 },
            for: 0.2
        )
        XCTAssertTrue(didStayOne)
        XCTAssertEqual(self.repository.writeCalls, [.add(isbn: pachinko.isbn)])
    }

    func test_진행중쓰기가실패하면_대기분의목표가같아도다시시도한다() async {
        await self.completeInitialLoad()
        self.repository.failAllWrites()
        let gate = self.repository.blockWrites(for: pachinko.isbn)

        await self.sut.add(pachinko)
        await gate.waitUntilArrived()
        await self.sut.add(pachinko)

        gate.open()

        let didRetry = await waitUntil { [repository] in repository?.writeCalls.count == 2 }
        XCTAssertTrue(didRetry)
        XCTAssertEqual(
            self.repository.writeCalls,
            [.add(isbn: pachinko.isbn), .add(isbn: pachinko.isbn)]
        )
    }

    func test_한책의쓰기가멈춰있어도_다른책의쓰기는진행한다() async {
        await self.completeInitialLoad()
        let pachinkoGate = self.repository.blockWrites(for: pachinko.isbn)

        await self.sut.add(pachinko)
        await pachinkoGate.waitUntilArrived()
        await self.sut.add(toji)

        let didProceed = await waitUntil { [repository] in
            repository?.writeCalls.contains(.add(isbn: "2")) == true
        }
        XCTAssertTrue(didProceed)
        pachinkoGate.open()
    }

    func test_쓰기가실패하고최신의도가없으면_실패를한번알린다() async {
        await self.completeInitialLoad()
        self.repository.failAllWrites()
        let failures = AsyncValueRecorder(self.sut.observeFailures())

        await self.sut.add(pachinko)

        let received = try? await failures.wait(untilCount: 1)
        XCTAssertEqual(
            received,
            [FavoriteWriteFailure(isbn: pachinko.isbn, desiredIsFavorite: true)]
        )
    }

    func test_제거가실패하면_제거하지못했다는의도로알린다() async {
        await self.completeInitialLoad()
        self.repository.failAllWrites()
        let failures = AsyncValueRecorder(self.sut.observeFailures())

        await self.sut.remove(isbn: pachinko.isbn)

        let received = try? await failures.wait(untilCount: 1)
        XCTAssertEqual(received?.first?.desiredIsFavorite, false)
    }

    func test_실패한쓰기위에더최신의도가대기중이면_그실패는알리지않는다() async {
        await self.completeInitialLoad()
        self.repository.failWrites { call in
            if case .add = call { return true } else { return false }
        }
        let gate = self.repository.blockWrites(for: pachinko.isbn)
        let failures = AsyncValueRecorder(self.sut.observeFailures())

        await self.sut.add(pachinko)
        await gate.waitUntilArrived()
        await self.sut.remove(isbn: pachinko.isbn)

        gate.open()

        let didRunBoth = await waitUntil { [repository] in repository?.writeCalls.count == 2 }
        XCTAssertTrue(didRunBoth)
        XCTAssertEqual(failures.values, [])
    }

    func test_대기중이던최신의도까지실패하면_그실패는알린다() async {
        await self.completeInitialLoad()
        self.repository.failAllWrites()
        let gate = self.repository.blockWrites(for: pachinko.isbn)
        let failures = AsyncValueRecorder(self.sut.observeFailures())

        await self.sut.add(pachinko)
        await gate.waitUntilArrived()
        await self.sut.remove(isbn: pachinko.isbn)

        gate.open()

        let received = try? await failures.wait(untilCount: 1)
        XCTAssertEqual(received?.count, 1)
        XCTAssertEqual(received?.first?.desiredIsFavorite, false)
    }

    func test_쓰기가성공하면_실패를알리지않는다() async {
        await self.completeInitialLoad()
        let failures = AsyncValueRecorder(self.sut.observeFailures())

        await self.sut.add(pachinko)

        let didRun = await waitUntil { [repository] in repository?.writeCalls.count == 1 }
        XCTAssertTrue(didRun)
        let stayedSilent = await stayFalse({ !failures.values.isEmpty }, for: 0.1)
        XCTAssertTrue(stayedSilent)
    }

    func test_제출은_저장소완료를기다리지않고즉시반환한다() async {
        await self.completeInitialLoad()
        let gate = self.repository.blockWrites(for: pachinko.isbn)

        await self.sut.add(pachinko)

        await gate.waitUntilArrived()
        XCTAssertEqual(self.repository.writeCalls.count, 1)
        gate.open()
    }
}
