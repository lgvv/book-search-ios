// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FeatureSupport",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "FeatureSupport", targets: ["FeatureSupport"])
    ],
    dependencies: [
        .package(path: "../../Shared/TestSupport")
    ],
    targets: [
        .target(
            name: "FeatureSupport",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "FeatureSupportTests",
            dependencies: [
                "FeatureSupport",
                .product(name: "TestSupport", package: "TestSupport")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
