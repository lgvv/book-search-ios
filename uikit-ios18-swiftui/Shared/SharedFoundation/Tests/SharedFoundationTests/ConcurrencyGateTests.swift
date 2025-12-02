import Foundation
import Testing

import TestSupport

@testable import SharedFoundation

struct ConcurrencyGateTests {

    @Test
    func 상한보다많이제출해도_동시실행수가상한을넘지않는다() async {
        let capacity = 3
        let sut = ConcurrencyGate(capacity: capacity)
        let inFlight = Locked(0)
        let peak = Locked(0)

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 50 {
                group.addTask {
                    try? await sut.withPermit {
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

        #expect(peak.value == capacity)
        #expect(inFlight.value == 0)
    }

    @Test
    func 상한에0이하를주면_최소1로올린다() async throws {
        let sut = ConcurrencyGate(capacity: 0)

        let result = try await sut.withPermit { "통과" }

        #expect(result == "통과")
    }

    @Test
    func 작업이던져도_permit을반납한다() async {
        let sut = ConcurrencyGate(capacity: 1)
        struct Boom: Error {}

        await #expect(throws: Boom.self) {
            try await sut.withPermit { throw Boom() }
        }

        let didPass = await waitUntil {
            (try? await sut.withPermit { true }) ?? false
        }
        #expect(didPass)
    }

    @Test
    func permit이모두잡혀있으면_반납전까지대기한다() async {
        let sut = ConcurrencyGate(capacity: 1)
        let holder = Gate()
        let didEnterSecond = Locked(false)

        let first = Task { try? await sut.withPermit { await holder.wait() } }
        await holder.waitUntilArrived()

        let second = Task { try? await sut.withPermit { didEnterSecond.withValue { $0 = true } } }

        let stayedOut = await stayFalse { didEnterSecond.value }
        #expect(stayedOut)

        holder.open()
        await first.value
        await second.value
        #expect(didEnterSecond.value)
    }

    @Test
    func 대기자가있으면_permit을반납하지않고그대로넘긴다() async {
        let sut = ConcurrencyGate(capacity: 2)
        let completed = Locked(0)

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 30 {
                group.addTask {
                    try? await sut.withPermit {
                        await Task.yield()
                        completed.withValue { $0 += 1 }
                    }
                }
            }
        }

        #expect(completed.value == 30)
    }

    @Test
    func 대기중에취소되면_permit을받지않고끝난다() async {
        let sut = ConcurrencyGate(capacity: 1)
        let holder = Gate()
        let first = Task { try? await sut.withPermit { await holder.wait() } }
        await holder.waitUntilArrived()

        let didRun = Locked(false)
        let waiting = Task {
            try await sut.withPermit { didRun.withValue { $0 = true } }
        }
        let didEnqueue = await waitUntil { sut.waiterCountForTesting == 1 }
        #expect(didEnqueue)

        waiting.cancel()

        await #expect(throws: CancellationError.self) { try await waiting.value }
        #expect(!(didRun.value))

        holder.open()
        await first.value
    }

    @Test
    func 취소된waiter가있어도_남은대기자는permit을받는다() async {
        let sut = ConcurrencyGate(capacity: 1)
        let holder = Gate()
        let first = Task { try? await sut.withPermit { await holder.wait() } }
        await holder.waitUntilArrived()

        let cancelled = Task { try await sut.withPermit {} }
        let didEnqueue = await waitUntil { sut.waiterCountForTesting == 1 }
        #expect(didEnqueue)
        cancelled.cancel()
        _ = try? await cancelled.value

        holder.open()
        await first.value

        let didPass = await waitUntil {
            (try? await sut.withPermit { true }) ?? false
        }
        #expect(didPass)
    }

    @Test
    func 이미취소된태스크는_대기열에들어가지않고곧바로끝난다() async {
        let sut = ConcurrencyGate(capacity: 1)
        let task = Task { () -> Bool in
            while !Task.isCancelled { await Task.yield() }
            do {
                try await sut.withPermit {}
                return false
            } catch {
                return true
            }
        }

        task.cancel()

        let didThrow = await task.value
        #expect(didThrow)
        #expect(sut.waiterCountForTesting == 0)
    }

    @Test
    func CPU작업용기본게이트는_상한이2에서4사이다() async {
        let sut = ConcurrencyGate.forCPUBoundWork()
        let peak = Locked(0)
        let inFlight = Locked(0)

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 40 {
                group.addTask {
                    try? await sut.withPermit {
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

        #expect(peak.value >= 2)
        #expect(peak.value <= 4)
    }
}
