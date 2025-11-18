// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Persistence",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "PersistenceInterface", targets: ["PersistenceInterface"]),
        .library(name: "Persistence", targets: ["Persistence"])
    ],
    dependencies: [
        .package(path: "../SharedFoundation"),
        .package(path: "../TestSupport"),
    ],
    targets: [
        .target(
            name: "PersistenceInterface",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "Persistence",
            dependencies: [
                "PersistenceInterface",
                .product(name: "SharedFoundation", package: "SharedFoundation")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "PersistenceTests",
            dependencies: [
                "Persistence",
                "PersistenceInterface",
                .product(name: "TestSupport", package: "TestSupport")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
