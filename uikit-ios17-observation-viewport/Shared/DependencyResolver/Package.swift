// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "DependencyResolver",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "DependencyResolver", targets: ["DependencyResolver"]),
    ],
    dependencies: [
        .package(path: "../SharedFoundation"),
    ],
    targets: [
        .target(
            name: "DependencyResolver",
            dependencies: [
                .product(name: "SharedFoundation", package: "SharedFoundation")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "DependencyResolverTests",
            dependencies: ["DependencyResolver"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
