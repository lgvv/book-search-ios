// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FavoriteDomain",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "FavoriteCore", targets: ["FavoriteCore"])
    ],
    dependencies: [
        .package(path: "../../Domain/BookDomain"),
        .package(path: "../../Shared/DependencyResolver"),
        .package(path: "../../Shared/SharedFoundation"),
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
        )
    ]
)
