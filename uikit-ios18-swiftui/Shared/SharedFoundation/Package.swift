// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SharedFoundation",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "SharedFoundation", targets: ["SharedFoundation"])
    ],
    dependencies: [
        .package(path: "../TestSupport")
    ],
    targets: [
        .target(
            name: "SharedFoundation",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "SharedFoundationTests",
            dependencies: [
                "SharedFoundation",
                .product(name: "TestSupport", package: "TestSupport")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
