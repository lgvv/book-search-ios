// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "BookUI",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "BookUI", targets: ["BookUI"])
    ],
    dependencies: [
        .package(path: "../../Domain/BookDomain"),
        .package(path: "../../Shared/ImageLoader"),
        .package(path: "../DesignSystem")
    ],
    targets: [
        .target(
            name: "BookUI",
            dependencies: [
                .product(name: "BookModel", package: "BookDomain"),
                .product(name: "ImageUI", package: "ImageLoader"),
                .product(name: "DesignSystem", package: "DesignSystem")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
