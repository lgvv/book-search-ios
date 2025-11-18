// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ImageLoader",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "ImageLoader", targets: ["ImageLoader"]),
        .library(name: "ImageUI", targets: ["ImageUI"]),
        .library(name: "ImageLoaderContainer", targets: ["ImageLoaderContainer"]),
    ],
    dependencies: [
        .package(path: "../Persistence"),
        .package(path: "../SharedFoundation"),
        .package(path: "../TestSupport"),
    ],
    targets: [
        .target(
            name: "ImageLoader",
            dependencies: [
                .product(name: "PersistenceInterface", package: "Persistence"),
                .product(name: "SharedFoundation", package: "SharedFoundation")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "ImageUI",
            dependencies: ["ImageLoader"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "ImageLoaderContainer",
            dependencies: [
                "ImageLoader",
                .product(name: "PersistenceInterface", package: "Persistence")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "ImageLoaderTests",
            dependencies: [
                "ImageLoader",
                .product(name: "PersistenceInterface", package: "Persistence"),
                .product(name: "TestSupport", package: "TestSupport")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
