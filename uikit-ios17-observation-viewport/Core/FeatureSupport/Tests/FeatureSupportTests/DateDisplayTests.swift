import XCTest

@testable import FeatureSupport

final class DateDisplayTests: XCTestCase {

    private let sample = Date(timeIntervalSince1970: 1_728_982_800)

    private var utcCalendarDescription: String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return "\(calendar)"
    }

    func test_날짜만표기하면_점으로구분한여덟자리가나온다() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy.MM.dd"

        let result = DateDisplay.date(sample)

        XCTAssertEqual(result, formatter.string(from: sample))
        XCTAssertEqual(result.count, 10)
    }

    func test_날짜와시각을표기하면_날짜뒤에24시간제시각이붙는다() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy.MM.dd HH:mm"

        let result = DateDisplay.dateTime(sample)

        XCTAssertEqual(result, formatter.string(from: sample))
        XCTAssertEqual(result.count, 16)
    }

    func test_시스템로케일이바뀌어도_숫자표기가유지된다() {
        let result = DateDisplay.date(sample)

        let digitsOnly = result.filter { $0.isNumber }

        XCTAssertEqual(digitsOnly.count, 8)
        XCTAssertTrue(result.allSatisfy { $0.isNumber || $0 == "." })
    }

    func test_상대시각은_한국어로표기한다() {
        let oneHourAgo = Date().addingTimeInterval(-3_600)

        let result = DateDisplay.relative(oneHourAgo)

        XCTAssertTrue(
            result.contains(where: { $0.isHangul }),
            "한국어 상대 표기가 아닙니다: \(result)"
        )
    }

    func test_과거시각과미래시각은_다르게표기한다() {
        let past = Date().addingTimeInterval(-7_200)
        let future = Date().addingTimeInterval(7_200)

        let pastText = DateDisplay.relative(past)
        let futureText = DateDisplay.relative(future)

        XCTAssertNotEqual(pastText, futureText)
    }
}

private extension Character {
    var isHangul: Bool {
        unicodeScalars.allSatisfy { (0xAC00 ... 0xD7A3).contains($0.value) }
    }
}
