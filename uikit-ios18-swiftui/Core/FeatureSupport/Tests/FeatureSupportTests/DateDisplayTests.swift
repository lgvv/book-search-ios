import Foundation
import Testing

@testable import FeatureSupport

struct DateDisplayTests {

    private let sample = Date(timeIntervalSince1970: 1_728_982_800)

    private var utcCalendarDescription: String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return "\(calendar)"
    }

    @Test
    func 날짜만표기하면_점으로구분한여덟자리가나온다() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy.MM.dd"

        let result = DateDisplay.date(sample)

        #expect(result == formatter.string(from: sample))
        #expect(result.count == 10)
    }

    @Test
    func 날짜와시각을표기하면_날짜뒤에24시간제시각이붙는다() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy.MM.dd HH:mm"

        let result = DateDisplay.dateTime(sample)

        #expect(result == formatter.string(from: sample))
        #expect(result.count == 16)
    }

    @Test
    func 시스템로케일이바뀌어도_숫자표기가유지된다() {
        let result = DateDisplay.date(sample)

        let digitsOnly = result.filter { $0.isNumber }

        #expect(digitsOnly.count == 8)
        #expect(result.allSatisfy { $0.isNumber || $0 == "." })
    }

    @Test
    func 상대시각은_한국어로표기한다() {
        let oneHourAgo = Date().addingTimeInterval(-3_600)

        let result = DateDisplay.relative(oneHourAgo)

        #expect(result.contains(where: { $0.isHangul }), "한국어 상대 표기가 아닙니다: \(result)")
    }

    @Test
    func 과거시각과미래시각은_다르게표기한다() {
        let past = Date().addingTimeInterval(-7_200)
        let future = Date().addingTimeInterval(7_200)

        let pastText = DateDisplay.relative(past)
        let futureText = DateDisplay.relative(future)

        #expect(pastText != futureText)
    }
}

private extension Character {
    var isHangul: Bool {
        unicodeScalars.allSatisfy { (0xAC00 ... 0xD7A3).contains($0.value) }
    }
}
