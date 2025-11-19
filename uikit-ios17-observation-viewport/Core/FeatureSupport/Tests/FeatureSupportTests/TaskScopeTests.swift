import XCTest

import TestSupport

@testable import FeatureSupport

@MainActor
final class TaskScopeTests: XCTestCase {

    private enum ID: Hashable, Sendable {
        case 검색
        case 즐겨찾기관찰
    }

    func test_같은ID로다시실행하면_이전작업을취소한다() async {
        let sut = TaskScope<ID>()
        let firstWasCancelled = Locked(false)
        let started = Gate()

        sut.run(.검색) {
            await started.wait()
            do {
                try await Task.sleep(nanoseconds: 5_000_000_000)
            } catch {
                firstWasCancelled.withValue { $0 = true }
            }
        }
        await started.waitUntilArrived()
        started.open()
        await Task.yield()
        sut.run(.검색) {}

        let didCancel = await waitUntil { firstWasCancelled.value }
        XCTAssertTrue(didCancel)
    }

    func test_다른ID로실행하면_기존작업을취소하지않는다() async {
        let sut = TaskScope<ID>()
        let didFinish = Locked(false)
        let gate = Gate()

        sut.run(.검색) {
            await gate.wait()
            guard !Task.isCancelled else { return }
            didFinish.withValue { $0 = true }
        }
        await gate.waitUntilArrived()
        sut.run(.즐겨찾기관찰) {}
        gate.open()

        let didComplete = await waitUntil { didFinish.value }
        XCTAssertTrue(didComplete)
    }

    func test_cancel을부르면_그ID의작업이취소된다() async {
        let sut = TaskScope<ID>()
        let wasCancelled = Locked(false)
        let started = Gate()

        sut.run(.검색) {
            await started.wait()
            do {
                try await Task.sleep(nanoseconds: 5_000_000_000)
            } catch {
                wasCancelled.withValue { $0 = true }
            }
        }
        await started.waitUntilArrived()
        started.open()
        await Task.yield()

        sut.cancel(.검색)

        let didCancel = await waitUntil { wasCancelled.value }
        XCTAssertTrue(didCancel)
    }

    func test_cancelAll을부르면_보관된작업이모두취소된다() async {
        let sut = TaskScope<ID>()
        let cancelledCount = Locked(0)
        let started = Gate()

        for id in [ID.검색, ID.즐겨찾기관찰] {
            sut.run(id) {
                await started.wait()
                do {
                    try await Task.sleep(nanoseconds: 5_000_000_000)
                } catch {
                    cancelledCount.withValue { $0 += 1 }
                }
            }
        }
        await started.waitUntilArrived(2)
        started.open()
        await Task.yield()

        sut.cancelAll()

        let didCancelBoth = await waitUntil { cancelledCount.value == 2 }
        XCTAssertTrue(didCancelBoth, "취소된 작업: \(cancelledCount.value)")
    }

    func test_스코프가해제되면_보관된작업이취소된다() async {
        let wasCancelled = Locked(false)
        let started = Gate()

        do {
            let sut = TaskScope<ID>()
            sut.run(.검색) {
                await started.wait()
                do {
                    try await Task.sleep(nanoseconds: 5_000_000_000)
                } catch {
                    wasCancelled.withValue { $0 = true }
                }
            }
            await started.waitUntilArrived()
            started.open()
            await Task.yield()
        }

        let didCancel = await waitUntil { wasCancelled.value }
        XCTAssertTrue(didCancel)
    }

    func test_먼저끝난작업이_뒤에들어온같은ID작업을지우지않는다() async {
        let sut = TaskScope<ID>()
        let finished = Gate()
        let secondWasCancelled = Locked(false)

        sut.run(.검색) {}
        await Task.yield()
        await Task.yield()

        sut.run(.검색) {
            await finished.wait()
            do {
                try await Task.sleep(nanoseconds: 5_000_000_000)
            } catch {
                secondWasCancelled.withValue { $0 = true }
            }
        }
        await finished.waitUntilArrived()
        finished.open()
        await Task.yield()

        sut.cancelAll()

        let didCancel = await waitUntil { secondWasCancelled.value }
        XCTAssertTrue(didCancel, "두 번째 작업이 추적 밖으로 새어나갔습니다")
    }
}
