import Foundation
import Testing

@testable import FeatureSupport

@MainActor
struct ActionQueueTests {

    @Test
    func 재진입이없으면_액션을받는즉시처리한다() {
        let sut = ActionQueue<String>()
        var processed: [String] = []

        sut.send("첫번째") { processed.append($0) }
        sut.send("두번째") { processed.append($0) }

        #expect(processed == ["첫번째", "두번째"])
    }

    @Test
    func 처리도중들어온send는_현재처리가끝난뒤에실행된다() {
        let sut = ActionQueue<String>(onViolation: { _ in })
        var processed: [String] = []

        sut.send("바깥") { action in
            processed.append(action)
            if action == "바깥" {
                sut.send("안쪽") { _ in }
            }
        }

        #expect(processed == ["바깥", "안쪽"])
    }

    @Test
    func 중첩send의처리클로저는_무시되고바깥클로저가처리한다() {
        let sut = ActionQueue<String>(onViolation: { _ in })
        var byOuter: [String] = []
        var byInner: [String] = []

        sut.send("바깥") { action in
            byOuter.append(action)
            if action == "바깥" {
                sut.send("안쪽") { byInner.append($0) }
            }
        }

        #expect(byOuter == ["바깥", "안쪽"])
        #expect(byInner == [])
    }

    @Test
    func 처리도중send가들어오면_위반으로보고한다() {
        let reported = LockedBox<[String]>([])
        let sut = ActionQueue<String>(onViolation: { reported.value.append($0) })

        sut.send("바깥") { action in
            if action == "바깥" {
                sut.send("안쪽") { _ in }
            }
        }

        #expect(reported.value == ["안쪽"])
    }

    @Test
    func 재진입이연쇄로일어나도_전부순서대로처리한다() {
        let sut = ActionQueue<Int>(onViolation: { _ in })
        var processed: [Int] = []

        sut.send(0) { action in
            processed.append(action)
            if action < 3 {
                sut.send(action + 1) { _ in }
            }
        }

        #expect(processed == [0, 1, 2, 3])
    }

    @Test
    func 드레인이끝나면_다음send는다시즉시처리된다() {
        let sut = ActionQueue<String>(onViolation: { _ in })
        var processed: [String] = []

        sut.send("첫턴") { action in
            processed.append(action)
            if action == "첫턴" {
                sut.send("첫턴중첩") { processed.append($0) }
            }
        }

        sut.send("둘째턴") { processed.append($0) }

        #expect(processed == ["첫턴", "첫턴중첩", "둘째턴"])
    }
}

private final class LockedBox<Value>: @unchecked Sendable {
    var value: Value
    init(_ value: Value) { self.value = value }
}
