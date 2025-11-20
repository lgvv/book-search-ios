import Foundation
import Testing

@testable import SharedFoundation

struct LockIsolatedTests {

    @Test
    func 동시에증분해도_갱신이유실되지않는다() async {
        let sut = LockIsolated(0)
        let iterations = 1_000

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< iterations {
                group.addTask { sut.withValue { $0 += 1 } }
            }
        }

        #expect(sut.value == iterations)
    }

    @Test
    func 읽고쓰기가한임계구역이면_중간상태가밖으로새지않는다() async {
        let sut = LockIsolated([String: Bool]())
        let winners = LockIsolated(0)

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 500 {
                group.addTask {
                    let isFirst = sut.withValue { state -> Bool in
                        guard state["책A"] == nil else { return false }
                        state["책A"] = true
                        return true
                    }
                    if isFirst {
                        winners.withValue { $0 += 1 }
                    }
                }
            }
        }

        #expect(winners.value == 1)
    }

    @Test
    func withValue가값을돌려주면_그값을그대로전달한다() {
        let sut = LockIsolated([1, 2, 3])

        let removed = sut.withValue { $0.removeLast() }

        #expect(removed == 3)
        #expect(sut.value == [1, 2])
    }

    @Test
    func withValue가던지면_그오류가전달되고락이풀린다() {
        let sut = LockIsolated(0)
        struct Boom: Error {}

        #expect(throws: Boom.self) {
            try sut.withValue { _ -> Int in throw Boom() }
        }

        #expect(sut.value == 0)
    }
}
