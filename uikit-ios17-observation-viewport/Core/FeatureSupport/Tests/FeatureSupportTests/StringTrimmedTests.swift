import Foundation
import Testing

@testable import FeatureSupport

struct StringTrimmedTests {

    @Test
    func 앞뒤공백이있으면_제거한다() {
        let input = "  민음사  "

        let result = input.trimmed

        #expect(result == "민음사")
    }

    @Test
    func 가운데공백은_유지한다() {
        let input = " 토지 완전판 "

        let result = input.trimmed

        #expect(result == "토지 완전판")
    }

    @Test
    func 줄바꿈과탭도_공백으로보고제거한다() {
        let input = "\n\t민음사\t\n"

        let result = input.trimmed

        #expect(result == "민음사")
    }

    @Test
    func 공백만있는문자열은_비어있다고본다() {
        let input = "   \n  "

        #expect(input.isBlank)
        #expect(input.trimmed == "")
    }

    @Test
    func 내용이있으면_비어있지않다() {
        let input = " 파친코 "

        #expect(!(input.isBlank))
    }

    @Test
    func 빈문자열은_비어있다고본다() {
        #expect("".isBlank)
    }
}
