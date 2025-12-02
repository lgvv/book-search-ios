import UIKit

import DesignSystem

@MainActor
public enum BookListLayout {

    public static let idealItemWidth: CGFloat = 340

    private static let estimatedItemHeight: CGFloat = 100

    public static func columns(for width: CGFloat) -> Int {
        max(1, Int(width / self.idealItemWidth))
    }

    public static func columns(for environment: NSCollectionLayoutEnvironment) -> Int {
        self.columns(for: environment.container.effectiveContentSize.width)
    }

    public static func section(
        environment: NSCollectionLayoutEnvironment,
        swipeActions: UICollectionLayoutListConfiguration.SwipeActionsConfigurationProvider? = nil
    ) -> NSCollectionLayoutSection {
        let columns = self.columns(for: environment)
        guard columns > 1 else {
            return self.listSection(environment: environment, swipeActions: swipeActions)
        }
        return self.gridSection(columns: columns)
    }

    public static func listSection(
        environment: NSCollectionLayoutEnvironment,
        swipeActions: UICollectionLayoutListConfiguration.SwipeActionsConfigurationProvider? = nil
    ) -> NSCollectionLayoutSection {
        var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        configuration.showsSeparators = false
        configuration.backgroundColor = .dsBackground
        configuration.trailingSwipeActionsConfigurationProvider = swipeActions
        return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
    }

    private static func gridSection(columns: Int) -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0 / CGFloat(columns)),
                heightDimension: .estimated(self.estimatedItemHeight)
            )
        )

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(self.estimatedItemHeight)
            ),
            repeatingSubitem: item,
            count: columns
        )

        return NSCollectionLayoutSection(group: group)
    }
}
