import Foundation
import Testing

import TestSupport

@testable import SharedFoundation

struct SerialTaskQueueTests {

    @Test
    func 여러작업을제출하면_제출순서대로실행한다() async throws {
        let sut = SerialTaskQueue()
        let order = Locked<[Int]>([])

        let tasks = (1 ... 20).map { index in
            sut.enqueue {
                await Task.yield()
                order.withValue { $0.append(index) }
            }
        }
        for task in tasks {
            _ = try await task.value
        }

        #expect(order.value == Array(1 ... 20))
    }

    @Test
    func 앞작업이끝나기전에는_뒤작업이시작되지않는다() async throws {
        let sut = SerialTaskQueue()
        let gate = Gate()
        let didStartSecond = Locked(false)

        let first = sut.enqueue { await gate.wait() }
        let second = sut.enqueue { didStartSecond.withValue { $0 = true } }

        await gate.waitUntilArrived()

        let stayedIdle = await stayFalse { didStartSecond.value }
        #expect(stayedIdle)

        gate.open()
        _ = try await first.value
        _ = try await second.value
        #expect(didStartSecond.value)
    }

    @Test
    func 앞작업이던져도_뒤작업은실행된다() async throws {
        let sut = SerialTaskQueue()
        struct Boom: Error {}
        let didRunSecond = Locked(false)

        let failing = sut.enqueue { throw Boom() }
        let following = sut.enqueue { didRunSecond.withValue { $0 = true } }

        do {
            _ = try await failing.value
            Issue.record("앞 작업은 던져야 한다")
        } catch {
            #expect(error is Boom)
        }
        _ = try await following.value
        #expect(didRunSecond.value)
    }

    @Test
    func 작업이던지면_그오류가호출부로전달된다() async {
        let sut = SerialTaskQueue()
        struct Boom: Error, Equatable { let code: Int }

        let task = sut.enqueue { throw Boom(code: 42) }

        do {
            _ = try await task.value
            Issue.record("오류가 전달되어야 한다")
        } catch {
            #expect(error as? Boom == Boom(code: 42))
        }
    }

    @Test
    func 호출자가취소돼도_큐에든작업은끝까지실행된다() async throws {
        let sut = SerialTaskQueue()
        let gate = Gate()
        let didFinish = Locked(false)

        let caller = Task {
            _ = try? await sut.enqueue {
                await gate.wait()
                didFinish.withValue { $0 = true }
            }.value
        }
        await gate.waitUntilArrived()
        caller.cancel()
        gate.open()

        let didComplete = await waitUntil { didFinish.value }
        #expect(didComplete)
    }

    @Test
    func 작업이값을돌려주면_그값을그대로전달한다() async throws {
        let sut = SerialTaskQueue()

        let value = try await sut.enqueue { "결과" }.value

        #expect(value == "결과")
    }
}
