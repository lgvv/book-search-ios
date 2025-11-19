import XCTest

@testable import FeatureSupport

final class StringTrimmedTests: XCTestCase {

    func test_앞뒤공백이있으면_제거한다() {
        let input = "  민음사  "

        let result = input.trimmed

        XCTAssertEqual(result, "민음사")
    }

    func test_가운데공백은_유지한다() {
        let input = " 토지 완전판 "

        let result = input.trimmed

        XCTAssertEqual(result, "토지 완전판")
    }

    func test_줄바꿈과탭도_공백으로보고제거한다() {
        let input = "\n\t민음사\t\n"

        let result = input.trimmed

        XCTAssertEqual(result, "민음사")
    }

    func test_공백만있는문자열은_비어있다고본다() {
        let input = "   \n  "

        XCTAssertTrue(input.isBlank)
        XCTAssertEqual(input.trimmed, "")
    }

    func test_내용이있으면_비어있지않다() {
        let input = " 파친코 "

        XCTAssertFalse(input.isBlank)
    }

    func test_빈문자열은_비어있다고본다() {
        XCTAssertTrue("".isBlank)
    }
}
