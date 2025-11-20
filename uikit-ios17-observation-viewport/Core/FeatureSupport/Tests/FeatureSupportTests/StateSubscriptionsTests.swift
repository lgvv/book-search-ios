import Foundation
import Testing

@testable import FeatureSupport

@MainActor
struct StateSubscriptionsTests {

    private struct State: Equatable {
        var query = ""
        var count = 0
    }

    @Test
    func 구독을시작하면_현재값으로한번렌더한다() {
        let sut = StateSubscriptions<State>()
        var rendered: [(old: String?, new: String)] = []

        sut.add(scope: \.query, current: State(query: "민음사")) { old, new in
            rendered.append((old, new))
        }

        #expect(rendered.count == 1)
        #expect(rendered[0].old == nil)
        #expect(rendered[0].new == "민음사")
    }

    @Test
    func 구독한값이바뀌면_이전값과함께렌더한다() {
        let sut = StateSubscriptions<State>()
        var rendered: [(old: String?, new: String)] = []
        let initial = State(query: "민음사")
        sut.add(scope: \.query, current: initial) { old, new in
            rendered.append((old, new))
        }

        sut.notify(from: initial, to: State(query: "파친코"))

        #expect(rendered.count == 2)
        #expect(rendered[1].old == "민음사")
        #expect(rendered[1].new == "파친코")
    }

    @Test
    func 구독하지않은값만바뀌면_렌더하지않는다() {
        let sut = StateSubscriptions<State>()
        var renderCount = 0
        let initial = State(query: "민음사", count: 0)
        sut.add(scope: \.query, current: initial) { _, _ in renderCount += 1 }

        sut.notify(from: initial, to: State(query: "민음사", count: 1))

        #expect(renderCount == 1)
    }

    @Test
    func 상태가전혀바뀌지않으면_구독자에게알리지않는다() {
        let sut = StateSubscriptions<State>()
        var renderCount = 0
        let state = State(query: "민음사")
        sut.add(scope: \.query, current: state) { _, _ in renderCount += 1 }

        sut.notify(from: state, to: state)

        #expect(renderCount == 1)
    }

    @Test
    func 구독자가여럿이면_각자관심있는변화에만렌더한다() {
        let sut = StateSubscriptions<State>()
        var queryRenders = 0
        var countRenders = 0
        let initial = State(query: "민음사", count: 0)
        sut.add(scope: \.query, current: initial) { _, _ in queryRenders += 1 }
        sut.add(scope: \.count, current: initial) { _, _ in countRenders += 1 }

        sut.notify(from: initial, to: State(query: "민음사", count: 1))

        #expect(queryRenders == 1)
        #expect(countRenders == 2)
    }
}
