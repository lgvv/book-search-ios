// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Networks",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "NetworksInterface", targets: ["NetworksInterface"]),
        .library(name: "Networks", targets: ["Networks"])
    ],
    dependencies: [
        .package(path: "../TestSupport"),
    ],
    targets: [
        .target(
            name: "NetworksInterface",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .target(
            name: "Networks",
            dependencies: [
                "NetworksInterface"
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "NetworksTests",
            dependencies: [
                "Networks",
                "NetworksInterface",
                .product(name: "TestSupport", package: "TestSupport")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
