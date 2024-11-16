// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MemoFeature",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "MemoFeatureInterface", targets: ["MemoFeatureInterface"]),
        .library(name: "MemoFeature", targets: ["MemoFeature"])
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
        .package(path: "../../Domain/MemoDomain"),
        .package(path: "../../Domain/FavoriteDomain"),
        .package(path: "../../Shared/TestSupport"),
    ],
    targets: [
        .target(
            name: "MemoFeatureInterface",
            dependencies: [
                .product(name: "BookModel", package: "BookDomain")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "MemoFeature",
            dependencies: [
                "MemoFeatureInterface",
                .product(name: "BookModel", package: "BookDomain"),
                .product(name: "DependencyResolver", package: "DependencyResolver"),
                .product(name: "SharedFoundation", package: "SharedFoundation"),
                .product(name: "FeatureSupport", package: "FeatureSupport"),
                .product(name: "BookUI", package: "BookUI"),
                .product(name: "ImageUI", package: "ImageLoader"),
                .product(name: "DesignSystem", package: "DesignSystem"),
                .product(name: "CommonUI", package: "CommonUI"),
                .product(name: "MemoModel", package: "MemoDomain"),
                .product(name: "MemoCore", package: "MemoDomain"),
                .product(name: "FavoriteCore", package: "FavoriteDomain")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "MemoFeatureTests",
            dependencies: [
                "MemoFeature",
                "MemoFeatureInterface",
                .product(name: "BookModel", package: "BookDomain"),
                .product(name: "MemoModel", package: "MemoDomain"),
                .product(name: "MemoCore", package: "MemoDomain"),
                .product(name: "FavoriteCore", package: "FavoriteDomain"),
                .product(name: "SharedFoundation", package: "SharedFoundation"),
                .product(name: "DependencyResolver", package: "DependencyResolver"),
                .product(name: "TestSupport", package: "TestSupport")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
