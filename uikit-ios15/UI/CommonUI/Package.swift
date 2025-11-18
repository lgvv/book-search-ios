// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CommonUI",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "CommonUI", targets: ["CommonUI"])
    ],
    dependencies: [
        .package(path: "../DesignSystem")
    ],
    targets: [
        .target(
            name: "CommonUI",
            dependencies: [
                .product(name: "DesignSystem", package: "DesignSystem")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
