import Foundation

public enum DateDisplay {
    public static func date(_ date: Date) -> String {
        Self.dateFormatter.string(from: date)
    }

    public static func dateTime(_ date: Date) -> String {
        Self.dateTimeFormatter.string(from: date)
    }

    public static func relative(_ date: Date) -> String {
        date.formatted(Self.relativeStyle)
    }

    private static let displayLocale = Locale(identifier: "ko_KR")

    private static let relativeStyle = Date.RelativeFormatStyle(
        presentation: .named,
        unitsStyle: .wide
    )
    .locale(Self.displayLocale)

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()

    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        return formatter
    }()
}
