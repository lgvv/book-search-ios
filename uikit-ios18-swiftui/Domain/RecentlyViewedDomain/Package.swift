// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "RecentlyViewedDomain",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(name: "RecentlyViewedModel", targets: ["RecentlyViewedModel"]),
        .library(name: "RecentlyViewedCore", targets: ["RecentlyViewedCore"]),
        .library(name: "RecentlyViewedData", targets: ["RecentlyViewedData"])
    ],
    dependencies: [
        .package(path: "../../Domain/BookDomain"),
        .package(path: "../../Shared/DependencyResolver"),
        .package(path: "../../Shared/SharedFoundation"),
        .package(path: "../../Shared/Persistence"),
        .package(path: "../../Shared/TestSupport"),
    ],
    targets: [
        .target(
            name: "RecentlyViewedModel",
            dependencies: [
                .product(name: "BookModel", package: "BookDomain")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "RecentlyViewedCore",
            dependencies: [
                "RecentlyViewedModel",
                .product(name: "BookModel", package: "BookDomain"),
                .product(name: "DependencyResolver", package: "DependencyResolver"),
                .product(name: "SharedFoundation", package: "SharedFoundation")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "RecentlyViewedData",
            dependencies: [
                .product(name: "PersistenceInterface", package: "Persistence"),
                "RecentlyViewedModel",
                "RecentlyViewedCore",
                .product(name: "BookModel", package: "BookDomain"),
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "RecentlyViewedDomainTests",
            dependencies: [
                "RecentlyViewedModel",
                "RecentlyViewedCore",
                "RecentlyViewedData",
                .product(name: "BookModel", package: "BookDomain"),
                .product(name: "Persistence", package: "Persistence"),
                .product(name: "PersistenceInterface", package: "Persistence"),
                .product(name: "SharedFoundation", package: "SharedFoundation"),
                .product(name: "TestSupport", package: "TestSupport")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
