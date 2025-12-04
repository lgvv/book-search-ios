// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TestSupport",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(name: "TestSupport", targets: ["TestSupport"])
    ],
    targets: [
        .target(
            name: "TestSupport",
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
