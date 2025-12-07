import SwiftUI

public struct DSPrimaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .dsFont(.heading)
            .foregroundStyle(Color.dsOnTint)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Color.dsTint)
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.m))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(DSMotion.pressed, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == DSPrimaryButtonStyle {
    public static var dsPrimary: DSPrimaryButtonStyle { DSPrimaryButtonStyle() }
}
