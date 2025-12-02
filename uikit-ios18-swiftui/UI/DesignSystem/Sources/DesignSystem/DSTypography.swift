import UIKit

public enum DSTypography {
    public static func largeTitle() -> UIFont {
        scaled(size: 28, weight: .bold, relativeTo: .title1)
    }

    public static func title() -> UIFont {
        scaled(size: 22, weight: .bold, relativeTo: .title2)
    }

    public static func heading() -> UIFont {
        scaled(size: 17, weight: .semibold, relativeTo: .headline)
    }

    public static func body() -> UIFont {
        scaled(size: 17, weight: .regular, relativeTo: .body)
    }

    public static func caption() -> UIFont {
        scaled(size: 12, weight: .regular, relativeTo: .caption1)
    }

    private static func scaled(
        size: CGFloat,
        weight: UIFont.Weight,
        relativeTo style: UIFont.TextStyle
    ) -> UIFont {
        UIFontMetrics(forTextStyle: style)
            .scaledFont(for: .systemFont(ofSize: size, weight: weight))
    }
}

public enum DSSpacing {
    public static let xs: CGFloat = 4
    public static let s: CGFloat = 8
    public static let m: CGFloat = 12
    public static let l: CGFloat = 16
    public static let xl: CGFloat = 24
}

public enum DSRadius {
    public static let s: CGFloat = 6
    public static let m: CGFloat = 12
}
