// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "StorageCatalog",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "StorageCatalog", targets: ["StorageCatalog"])
    ],
    dependencies: [
        .package(path: "../../Shared/Persistence"),
    ],
    targets: [
        .target(
            name: "StorageCatalog",
            dependencies: [
                .product(name: "PersistenceInterface", package: "Persistence")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
