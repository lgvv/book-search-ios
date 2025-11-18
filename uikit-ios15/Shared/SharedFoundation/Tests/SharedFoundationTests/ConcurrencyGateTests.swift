import XCTest

import TestSupport

@testable import SharedFoundation

final class ConcurrencyGateTests: XCTestCase {

    func test_상한보다많이제출해도_동시실행수가상한을넘지않는다() async {
        let capacity = 3
        let sut = ConcurrencyGate(capacity: capacity)
        let inFlight = Locked(0)
        let peak = Locked(0)

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 50 {
                group.addTask {
                    await sut.withPermit {
                        inFlight.withValue { count in
                            count += 1
                            peak.withValue { $0 = max($0, count) }
                        }
                        await Task.yield()
                        inFlight.withValue { $0 -= 1 }
                    }
                }
            }
        }

        XCTAssertEqual(peak.value, capacity)
        XCTAssertEqual(inFlight.value, 0)
    }

    func test_상한에0이하를주면_최소1로올린다() async {
        let sut = ConcurrencyGate(capacity: 0)

        let result = await sut.withPermit { "통과" }

        XCTAssertEqual(result, "통과")
    }

    func test_작업이던져도_permit을반납한다() async {
        let sut = ConcurrencyGate(capacity: 1)
        struct Boom: Error {}

        do {
            try await sut.withPermit { throw Boom() }
            XCTFail("작업이 던져야 한다")
        } catch {
            XCTAssertTrue(error is Boom)
        }

        let didPass = await waitUntil {
            await sut.withPermit { true }
        }
        XCTAssertTrue(didPass)
    }

    func test_permit이모두잡혀있으면_반납전까지대기한다() async {
        let sut = ConcurrencyGate(capacity: 1)
        let holder = Gate()
        let didEnterSecond = Locked(false)

        let first = Task { await sut.withPermit { await holder.wait() } }
        await holder.waitUntilArrived()

        let second = Task { await sut.withPermit { didEnterSecond.withValue { $0 = true } } }

        let stayedOut = await stayFalse { didEnterSecond.value }
        XCTAssertTrue(stayedOut)

        holder.open()
        await first.value
        await second.value
        XCTAssertTrue(didEnterSecond.value)
    }

    func test_대기자가있으면_permit을반납하지않고그대로넘긴다() async {
        let sut = ConcurrencyGate(capacity: 2)
        let completed = Locked(0)

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 30 {
                group.addTask {
                    await sut.withPermit {
                        await Task.yield()
                        completed.withValue { $0 += 1 }
                    }
                }
            }
        }

        XCTAssertEqual(completed.value, 30)
    }

    func test_CPU작업용기본게이트는_상한이2에서4사이다() async {
        let sut = ConcurrencyGate.forCPUBoundWork()
        let peak = Locked(0)
        let inFlight = Locked(0)

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 40 {
                group.addTask {
                    await sut.withPermit {
                        inFlight.withValue { count in
                            count += 1
                            peak.withValue { $0 = max($0, count) }
                        }
                        await Task.yield()
                        inFlight.withValue { $0 -= 1 }
                    }
                }
            }
        }

        XCTAssertGreaterThanOrEqual(peak.value, 2)
        XCTAssertLessThanOrEqual(peak.value, 4)
    }
}
