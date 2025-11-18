import XCTest

@testable import SharedFoundation

final class ResourceStateTests: XCTestCase {

    func test_loaded면_값을돌려준다() {
        let sut = ResourceState.loaded([1, 2, 3])

        let value = sut.value

        XCTAssertEqual(value, [1, 2, 3])
    }

    func test_loading이면_값이없다() {
        let sut = ResourceState<[Int]>.loading

        let value = sut.value

        XCTAssertNil(value)
    }

    func test_failed면_값이없다() {
        let sut = ResourceState<[Int]>.failed

        let value = sut.value

        XCTAssertNil(value)
    }

    func test_확인된빈목록은_값이있는빈배열이다() {
        let sut = ResourceState<[Int]>.loaded([])

        let value = sut.value

        XCTAssertEqual(value, [])
        XCTAssertNotNil(value)
    }

    func test_isStale을주지않으면_기본은신선함이다() {
        let sut = ResourceState.loaded([1])

        let isStale = sut.isStale

        XCTAssertFalse(isStale)
    }

    func test_isStale인loaded는_값을유지한채뒤처짐만알린다() {
        let sut = ResourceState.loaded([1, 2], isStale: true)

        XCTAssertEqual(sut.value, [1, 2])
        XCTAssertTrue(sut.isStale)
    }

    func test_loading과failed는_뒤처짐개념이없다() {
        XCTAssertFalse(ResourceState<[Int]>.loading.isStale)
        XCTAssertFalse(ResourceState<[Int]>.failed.isStale)
    }

    func test_같은값이라도_isStale이다르면다른상태다() {
        let fresh = ResourceState.loaded([1])
        let stale = ResourceState.loaded([1], isStale: true)

        XCTAssertNotEqual(fresh, stale)
    }

    func test_loading과failed와빈loaded는_서로다르다() {
        let loading = ResourceState<[Int]>.loading
        let failed = ResourceState<[Int]>.failed
        let empty = ResourceState<[Int]>.loaded([])

        XCTAssertNotEqual(loading, failed)
        XCTAssertNotEqual(loading, empty)
        XCTAssertNotEqual(failed, empty)
    }
}
