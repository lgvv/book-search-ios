// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SearchFeature",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "SearchFeatureInterface", targets: ["SearchFeatureInterface"]),
        .library(name: "SearchFeature", targets: ["SearchFeature"])
    ],
    dependencies: [
        .package(path: "../../Domain/BookDomain"),
        .package(path: "../../Shared/DependencyResolver"),
        .package(path: "../../Shared/SharedFoundation"),
        .package(path: "../../Core/FeatureSupport"),
        .package(path: "../../Shared/ImageLoader"),
        .package(path: "../../UI/BookUI"),
        .package(path: "../../UI/CommonUI"),
        .package(path: "../../UI/DesignSystem"),
        .package(path: "../../Domain/FavoriteDomain"),
        .package(path: "../../Domain/RecentSearchDomain"),
        .package(path: "../../Domain/MemoDomain"),
        .package(path: "../../Shared/TestSupport"),
    ],
    targets: [
        .target(
            name: "SearchFeatureInterface",
            dependencies: [
                .product(name: "BookModel", package: "BookDomain")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "SearchFeature",
            dependencies: [
                "SearchFeatureInterface",
                .product(name: "BookModel", package: "BookDomain"),
                .product(name: "DependencyResolver", package: "DependencyResolver"),
                .product(name: "SharedFoundation", package: "SharedFoundation"),
                .product(name: "FeatureSupport", package: "FeatureSupport"),
                .product(name: "BookUI", package: "BookUI"),
                .product(name: "ImageUI", package: "ImageLoader"),
                .product(name: "CommonUI", package: "CommonUI"),
                .product(name: "DesignSystem", package: "DesignSystem"),
                .product(name: "BookCore", package: "BookDomain"),
                .product(name: "RecentSearchCore", package: "RecentSearchDomain"),
                .product(name: "FavoriteCore", package: "FavoriteDomain"),
                .product(name: "MemoCore", package: "MemoDomain")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "SearchFeatureTests",
            dependencies: [
                "SearchFeature",
                "SearchFeatureInterface",
                .product(name: "BookModel", package: "BookDomain"),
                .product(name: "BookCore", package: "BookDomain"),
                .product(name: "FavoriteCore", package: "FavoriteDomain"),
                .product(name: "MemoCore", package: "MemoDomain"),
                .product(name: "RecentSearchCore", package: "RecentSearchDomain"),
                .product(name: "SharedFoundation", package: "SharedFoundation"),
                .product(name: "DependencyResolver", package: "DependencyResolver"),
                .product(name: "TestSupport", package: "TestSupport")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
