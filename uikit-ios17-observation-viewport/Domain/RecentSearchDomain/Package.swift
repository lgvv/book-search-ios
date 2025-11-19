// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RecentSearchDomain",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "RecentSearchCore", targets: ["RecentSearchCore"]),
        .library(name: "RecentSearchData", targets: ["RecentSearchData"])
    ],
    dependencies: [
        .package(path: "../../Core/StorageCatalog"),
        .package(path: "../../Shared/DependencyResolver"),
        .package(path: "../../Shared/Persistence"),
        .package(path: "../../Shared/SharedFoundation"),
        .package(path: "../../Shared/TestSupport"),
    ],
    targets: [
        .target(
            name: "RecentSearchCore",
            dependencies: [
                .product(name: "DependencyResolver", package: "DependencyResolver")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "RecentSearchData",
            dependencies: [
                .product(name: "StorageCatalog", package: "StorageCatalog"),
                .product(name: "PersistenceInterface", package: "Persistence"),
                .product(name: "SharedFoundation", package: "SharedFoundation"),
                "RecentSearchCore",
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "RecentSearchDomainTests",
            dependencies: [
                "RecentSearchCore",
                "RecentSearchData",
                .product(name: "PersistenceInterface", package: "Persistence"),
                .product(name: "TestSupport", package: "TestSupport")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
