import Foundation
import Testing

@testable import SharedFoundation

struct ResourceStateTests {

    @Test
    func loaded면_값을돌려준다() {
        let sut = ResourceState.loaded([1, 2, 3])

        let value = sut.value

        #expect(value == [1, 2, 3])
    }

    @Test
    func loading이면_값이없다() {
        let sut = ResourceState<[Int]>.loading

        let value = sut.value

        #expect(value == nil)
    }

    @Test
    func failed면_값이없다() {
        let sut = ResourceState<[Int]>.failed

        let value = sut.value

        #expect(value == nil)
    }

    @Test
    func 확인된빈목록은_값이있는빈배열이다() {
        let sut = ResourceState<[Int]>.loaded([])

        let value = sut.value

        #expect(value == [])
        #expect(value != nil)
    }

    @Test
    func isStale을주지않으면_기본은신선함이다() {
        let sut = ResourceState.loaded([1])

        let isStale = sut.isStale

        #expect(!(isStale))
    }

    @Test
    func isStale인loaded는_값을유지한채뒤처짐만알린다() {
        let sut = ResourceState.loaded([1, 2], isStale: true)

        #expect(sut.value == [1, 2])
        #expect(sut.isStale)
    }

    @Test
    func loading과failed는_뒤처짐개념이없다() {
        #expect(!(ResourceState<[Int]>.loading.isStale))
        #expect(!(ResourceState<[Int]>.failed.isStale))
    }

    @Test
    func 같은값이라도_isStale이다르면다른상태다() {
        let fresh = ResourceState.loaded([1])
        let stale = ResourceState.loaded([1], isStale: true)

        #expect(fresh != stale)
    }

    @Test
    func loading과failed와빈loaded는_서로다르다() {
        let loading = ResourceState<[Int]>.loading
        let failed = ResourceState<[Int]>.failed
        let empty = ResourceState<[Int]>.loaded([])

        #expect(loading != failed)
        #expect(loading != empty)
        #expect(failed != empty)
    }
}
