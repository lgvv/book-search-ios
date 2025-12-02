import Foundation
import Testing

import TestSupport

@testable import SharedFoundation

struct KeyedSerialQueueTests {

    @Test
    func 같은키로제출하면_제출순서대로실행한다() async throws {
        let sut = KeyedSerialQueue<String>()
        let order = Locked<[Int]>([])

        let tasks = (1 ... 20).map { index in
            sut.enqueue("책A") {
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
    func 같은키의앞작업이멈춰있으면_뒤작업도멈춘다() async throws {
        let sut = KeyedSerialQueue<String>()
        let gate = Gate()
        let didStartSecond = Locked(false)

        let first = sut.enqueue("책A") { await gate.wait() }
        let second = sut.enqueue("책A") { didStartSecond.withValue { $0 = true } }

        await gate.waitUntilArrived()

        let stayedIdle = await stayFalse { didStartSecond.value }
        #expect(stayedIdle)

        gate.open()
        _ = try await first.value
        _ = try await second.value
    }

    @Test
    func 다른키의작업은_앞키가멈춰있어도실행된다() async throws {
        let sut = KeyedSerialQueue<String>()
        let blocker = Gate()

        let blocked = sut.enqueue("책A") { await blocker.wait() }
        let independent = sut.enqueue("책B") { "완료" }

        let result = try await independent.value
        #expect(result == "완료")

        blocker.open()
        _ = try await blocked.value
    }

    @Test
    func 같은키에여러작업을제출하면_하나도생략하지않고전부실행한다() async throws {
        let sut = KeyedSerialQueue<String>()
        let runCount = Locked(0)

        let tasks = (1 ... 5).map { _ in
            sut.enqueue("책A") { runCount.withValue { $0 += 1 } }
        }
        for task in tasks {
            _ = try await task.value
        }

        #expect(runCount.value == 5)
    }

    @Test
    func 키의체인이비면_내부사전에서그키가사라진다() async throws {
        let sut = KeyedSerialQueue<String>()

        for index in 0 ..< 50 {
            _ = try await sut.enqueue("책\(index)") {}.value
        }

        let didDrain = await waitUntil { sut.trackedKeyCount == 0 }
        #expect(didDrain, "남은 키: \(sut.trackedKeyCount)")
    }

    @Test
    func 체인정리중에같은키로새작업이오면_새체인은지워지지않는다() async throws {
        let sut = KeyedSerialQueue<String>()
        let gate = Gate()

        _ = try await sut.enqueue("책A") {}.value
        let following = sut.enqueue("책A") {
            await gate.wait()
            return "이후"
        }

        await gate.waitUntilArrived()
        gate.open()

        let result = try await following.value
        #expect(result == "이후")
    }
}
