import SwiftUI
import UIKit

public enum DSFontStyle: Hashable {
    case largeTitle
    case title
    case heading
    case body
    case caption

    fileprivate var uiFont: UIFont {
        switch self {
        case .largeTitle: DSTypography.largeTitle()
        case .title: DSTypography.title()
        case .heading: DSTypography.heading()
        case .body: DSTypography.body()
        case .caption: DSTypography.caption()
        }
    }
}

extension View {
    public func dsFont(_ style: DSFontStyle) -> some View {
        self.modifier(DSFontModifier(style: style))
    }
}

private struct DSFontModifier: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let style: DSFontStyle

    func body(content: Content) -> some View {
        content.font(DSFontCache.font(self.style, at: self.dynamicTypeSize))
    }
}

@MainActor
private enum DSFontCache {
    private struct Key: Hashable {
        let style: DSFontStyle
        let size: DynamicTypeSize
    }

    private static var fonts: [Key: Font] = [:]

    static func font(_ style: DSFontStyle, at size: DynamicTypeSize) -> Font {
        let key = Key(style: style, size: size)
        if let cached = Self.fonts[key] {
            return cached
        }
        let font = Font(style.uiFont)
        Self.fonts[key] = font
        return font
    }
}
