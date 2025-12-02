// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "RecentlyViewedFeature",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "RecentlyViewedFeatureInterface", targets: ["RecentlyViewedFeatureInterface"]),
        .library(name: "RecentlyViewedFeature", targets: ["RecentlyViewedFeature"])
    ],
    dependencies: [
        .package(path: "../../Domain/BookDomain"),
        .package(path: "../../Shared/DependencyResolver"),
        .package(path: "../../Shared/SharedFoundation"),
        .package(path: "../../Core/FeatureSupport"),
        .package(path: "../../Shared/ImageLoader"),
        .package(path: "../../UI/BookUI"),
        .package(path: "../../UI/DesignSystem"),
        .package(path: "../../UI/CommonUI"),
        .package(path: "../../Domain/RecentlyViewedDomain"),
        .package(path: "../../Domain/FavoriteDomain"),
        .package(path: "../../Domain/MemoDomain"),
        .package(path: "../../Shared/TestSupport"),
    ],
    targets: [
        .target(
            name: "RecentlyViewedFeatureInterface",
            dependencies: [
                .product(name: "BookModel", package: "BookDomain")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "RecentlyViewedFeature",
            dependencies: [
                "RecentlyViewedFeatureInterface",
                .product(name: "BookModel", package: "BookDomain"),
                .product(name: "DependencyResolver", package: "DependencyResolver"),
                .product(name: "SharedFoundation", package: "SharedFoundation"),
                .product(name: "FeatureSupport", package: "FeatureSupport"),
                .product(name: "BookUI", package: "BookUI"),
                .product(name: "ImageUI", package: "ImageLoader"),
                .product(name: "DesignSystem", package: "DesignSystem"),
                .product(name: "CommonUI", package: "CommonUI"),
                .product(name: "RecentlyViewedModel", package: "RecentlyViewedDomain"),
                .product(name: "RecentlyViewedCore", package: "RecentlyViewedDomain"),
                .product(name: "FavoriteCore", package: "FavoriteDomain"),
                .product(name: "MemoCore", package: "MemoDomain")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "RecentlyViewedFeatureTests",
            dependencies: [
                "RecentlyViewedFeature",
                "RecentlyViewedFeatureInterface",
                .product(name: "BookModel", package: "BookDomain"),
                .product(name: "RecentlyViewedModel", package: "RecentlyViewedDomain"),
                .product(name: "RecentlyViewedCore", package: "RecentlyViewedDomain"),
                .product(name: "FavoriteCore", package: "FavoriteDomain"),
                .product(name: "MemoCore", package: "MemoDomain"),
                .product(name: "SharedFoundation", package: "SharedFoundation"),
                .product(name: "DependencyResolver", package: "DependencyResolver"),
                .product(name: "TestSupport", package: "TestSupport")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
