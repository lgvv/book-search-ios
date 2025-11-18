import XCTest

@testable import FeatureSupport

@MainActor
final class StateSubscriptionsTests: XCTestCase {

    private struct State: Equatable {
        var query = ""
        var count = 0
    }

    func test_구독을시작하면_현재값으로한번렌더한다() {
        let sut = StateSubscriptions<State>()
        var rendered: [(old: String?, new: String)] = []

        sut.add(scope: \.query, current: State(query: "민음사")) { old, new in
            rendered.append((old, new))
        }

        XCTAssertEqual(rendered.count, 1)
        XCTAssertNil(rendered[0].old)
        XCTAssertEqual(rendered[0].new, "민음사")
    }

    func test_구독한값이바뀌면_이전값과함께렌더한다() {
        let sut = StateSubscriptions<State>()
        var rendered: [(old: String?, new: String)] = []
        let initial = State(query: "민음사")
        sut.add(scope: \.query, current: initial) { old, new in
            rendered.append((old, new))
        }

        sut.notify(from: initial, to: State(query: "파친코"))

        XCTAssertEqual(rendered.count, 2)
        XCTAssertEqual(rendered[1].old, "민음사")
        XCTAssertEqual(rendered[1].new, "파친코")
    }

    func test_구독하지않은값만바뀌면_렌더하지않는다() {
        let sut = StateSubscriptions<State>()
        var renderCount = 0
        let initial = State(query: "민음사", count: 0)
        sut.add(scope: \.query, current: initial) { _, _ in renderCount += 1 }

        sut.notify(from: initial, to: State(query: "민음사", count: 1))

        XCTAssertEqual(renderCount, 1)
    }

    func test_상태가전혀바뀌지않으면_구독자에게알리지않는다() {
        let sut = StateSubscriptions<State>()
        var renderCount = 0
        let state = State(query: "민음사")
        sut.add(scope: \.query, current: state) { _, _ in renderCount += 1 }

        sut.notify(from: state, to: state)

        XCTAssertEqual(renderCount, 1)
    }

    func test_구독자가여럿이면_각자관심있는변화에만렌더한다() {
        let sut = StateSubscriptions<State>()
        var queryRenders = 0
        var countRenders = 0
        let initial = State(query: "민음사", count: 0)
        sut.add(scope: \.query, current: initial) { _, _ in queryRenders += 1 }
        sut.add(scope: \.count, current: initial) { _, _ in countRenders += 1 }

        sut.notify(from: initial, to: State(query: "민음사", count: 1))

        XCTAssertEqual(queryRenders, 1)
        XCTAssertEqual(countRenders, 2)
    }
}
