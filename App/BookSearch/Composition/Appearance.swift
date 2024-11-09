import UIKit

import DesignSystem

@MainActor
enum Appearance {
    static func configure(window: UIWindow) {
        window.tintColor = .dsTint

        configureNavigationBar()
        configureTabBar()
    }

    private static func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .dsBackground
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: UIColor.dsInk]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.dsInk]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }

    private static func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .dsBackground
        appearance.shadowColor = .dsSeparator

        let item = appearance.stackedLayoutAppearance
        item.normal.iconColor = .dsSubtleInk
        item.normal.titleTextAttributes = [.foregroundColor: UIColor.dsSubtleInk]
        item.selected.iconColor = .dsTint
        item.selected.titleTextAttributes = [.foregroundColor: UIColor.dsTint]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
