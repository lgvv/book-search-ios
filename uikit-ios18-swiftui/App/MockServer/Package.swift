// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MockServer",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(name: "MockServer", targets: ["MockServer"])
    ],
    dependencies: [
        .package(path: "../../Shared/Persistence"),
        .package(path: "../../Shared/SharedFoundation"),
        .package(path: "../../Shared/TestSupport"),
    ],
    targets: [
        .target(
            name: "MockServer",
            dependencies: [
                .product(name: "PersistenceInterface", package: "Persistence"),
                .product(name: "SharedFoundation", package: "SharedFoundation")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "MockServerTests",
            dependencies: [
                "MockServer",
                .product(name: "Persistence", package: "Persistence"),
                .product(name: "PersistenceInterface", package: "Persistence"),
                .product(name: "TestSupport", package: "TestSupport")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
