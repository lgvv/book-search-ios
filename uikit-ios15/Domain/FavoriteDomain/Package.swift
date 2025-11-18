// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FavoriteDomain",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "FavoriteCore", targets: ["FavoriteCore"]),
        .library(name: "FavoriteData", targets: ["FavoriteData"])
    ],
    dependencies: [
        .package(path: "../../Domain/BookDomain"),
        .package(path: "../../Shared/DependencyResolver"),
        .package(path: "../../Shared/SharedFoundation"),
        .package(path: "../../Shared/Networks"),
        .package(path: "../../Shared/TestSupport"),
    ],
    targets: [
        .target(
            name: "FavoriteCore",
            dependencies: [
                .product(name: "BookModel", package: "BookDomain"),
                .product(name: "DependencyResolver", package: "DependencyResolver"),
                .product(name: "SharedFoundation", package: "SharedFoundation")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "FavoriteData",
            dependencies: [
                .product(name: "NetworksInterface", package: "Networks"),
                "FavoriteCore",
                .product(name: "BookModel", package: "BookDomain"),
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "FavoriteDomainTests",
            dependencies: [
                "FavoriteCore",
                "FavoriteData",
                .product(name: "BookModel", package: "BookDomain"),
                .product(name: "NetworksInterface", package: "Networks"),
                .product(name: "SharedFoundation", package: "SharedFoundation"),
                .product(name: "TestSupport", package: "TestSupport")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
