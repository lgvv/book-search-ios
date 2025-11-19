import XCTest

import TestSupport

@testable import FeatureSupport

@MainActor
final class NonCancellableTaskQueueTests: XCTestCase {

    private enum ID: Hashable, Sendable {
        case 메모저장
        case 즐겨찾기
    }

    func test_같은ID로제출하면_제출순서대로실행한다() async {
        let sut = NonCancellableTaskQueue<ID>()
        let order = Locked<[Int]>([])

        for index in 1 ... 20 {
            sut.enqueue(.메모저장) {
                await Task.yield()
                order.withValue { $0.append(index) }
            }
        }

        let didFinish = await waitUntil { order.value.count == 20 }
        XCTAssertTrue(didFinish)
        XCTAssertEqual(order.value, Array(1 ... 20))
    }

    func test_앞작업이끝나기전에는_같은ID의뒤작업이시작되지않는다() async {
        let sut = NonCancellableTaskQueue<ID>()
        let gate = Gate()
        let didStartSecond = Locked(false)

        sut.enqueue(.메모저장) { await gate.wait() }
        sut.enqueue(.메모저장) { didStartSecond.withValue { $0 = true } }
        await gate.waitUntilArrived()

        let stayedIdle = await stayFalse { didStartSecond.value }
        XCTAssertTrue(stayedIdle)

        gate.open()
        let didStart = await waitUntil { didStartSecond.value }
        XCTAssertTrue(didStart)
    }

    func test_다른ID의작업은_서로를막지않는다() async {
        let sut = NonCancellableTaskQueue<ID>()
        let blocker = Gate()
        let didFinishOther = Locked(false)

        sut.enqueue(.메모저장) { await blocker.wait() }
        sut.enqueue(.즐겨찾기) { didFinishOther.withValue { $0 = true } }

        let didFinish = await waitUntil { didFinishOther.value }
        XCTAssertTrue(didFinish)

        blocker.open()
    }

    func test_큐가해제된뒤에도_제출된작업은끝까지실행된다() async {
        let didFinish = Locked(false)
        let gate = Gate()

        do {
            let sut = NonCancellableTaskQueue<ID>()
            sut.enqueue(.메모저장) {
                await gate.wait()
                didFinish.withValue { $0 = true }
            }
            await gate.waitUntilArrived()
        }
        gate.open()

        let didComplete = await waitUntil { didFinish.value }
        XCTAssertTrue(didComplete)
    }
}
