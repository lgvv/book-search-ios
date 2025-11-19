import UIKit

public extension UIColor {
    static let dsBackground = dynamic(light: 0xFFFFFF, dark: 0x0C0C0C)
    static let dsSurface = dynamic(light: 0xF4F4F4, dark: 0x1B1B1B)
    static let dsInk = dynamic(light: 0x111111, dark: 0xF2F2F2)
    static let dsSubtleInk = dynamic(light: 0x6E6E73, dark: 0x98989E)
    static let dsTint = dynamic(light: 0x111111, dark: 0xF2F2F2)
    static let dsOnTint = dynamic(light: 0xFFFFFF, dark: 0x111111)
    static let dsFavorite = dynamic(light: 0xD0453E, dark: 0xE5716A)
    static let dsSeparator = dynamic(light: 0xE7E7E7, dark: 0x2A2A2A)
}

private extension UIColor {
    static func dynamic(light: UInt32, dark: UInt32) -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        }
    }

    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
