// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "BookDetailFeature",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(name: "BookDetailFeatureInterface", targets: ["BookDetailFeatureInterface"]),
        .library(name: "BookDetailFeature", targets: ["BookDetailFeature"])
    ],
    dependencies: [
        .package(path: "../../Domain/BookDomain"),
        .package(path: "../../Shared/DependencyResolver"),
        .package(path: "../../Shared/SharedFoundation"),
        .package(path: "../../Shared/ImageLoader"),
        .package(path: "../../Core/FeatureSupport"),
        .package(path: "../../UI/DesignSystem"),
        .package(path: "../../Domain/FavoriteDomain"),
        .package(path: "../../Domain/MemoDomain"),
        .package(path: "../../Domain/RecentlyViewedDomain"),
        .package(path: "../../Shared/TestSupport"),
    ],
    targets: [
        .target(
            name: "BookDetailFeatureInterface",
            dependencies: [
                .product(name: "BookModel", package: "BookDomain")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "BookDetailFeature",
            dependencies: [
                "BookDetailFeatureInterface",
                .product(name: "BookModel", package: "BookDomain"),
                .product(name: "DependencyResolver", package: "DependencyResolver"),
                .product(name: "SharedFoundation", package: "SharedFoundation"),
                .product(name: "FeatureSupport", package: "FeatureSupport"),
                .product(name: "ImageUI", package: "ImageLoader"),
                .product(name: "DesignSystem", package: "DesignSystem"),
                .product(name: "FavoriteCore", package: "FavoriteDomain"),
                .product(name: "MemoCore", package: "MemoDomain"),
                .product(name: "RecentlyViewedCore", package: "RecentlyViewedDomain")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "BookDetailFeatureTests",
            dependencies: [
                "BookDetailFeature",
                "BookDetailFeatureInterface",
                .product(name: "BookModel", package: "BookDomain"),
                .product(name: "FavoriteCore", package: "FavoriteDomain"),
                .product(name: "MemoCore", package: "MemoDomain"),
                .product(name: "RecentlyViewedCore", package: "RecentlyViewedDomain"),
                .product(name: "SharedFoundation", package: "SharedFoundation"),
                .product(name: "DependencyResolver", package: "DependencyResolver"),
                .product(name: "TestSupport", package: "TestSupport")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
