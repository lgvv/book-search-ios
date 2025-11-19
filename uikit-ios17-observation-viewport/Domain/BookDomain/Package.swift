// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BookDomain",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "BookModel", targets: ["BookModel"]),
        .library(name: "BookCore", targets: ["BookCore"]),
        .library(name: "BookData", targets: ["BookData"])
    ],
    dependencies: [
        .package(path: "../../Shared/DependencyResolver"),
        .package(path: "../../Shared/Networks"),
        .package(path: "../../Shared/TestSupport")
    ],
    targets: [
        .target(
            name: "BookModel",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "BookCore",
            dependencies: [
                "BookModel",
                .product(name: "DependencyResolver", package: "DependencyResolver")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "BookData",
            dependencies: [
                "BookCore",
                "BookModel",
                .product(name: "NetworksInterface", package: "Networks")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "BookDomainTests",
            dependencies: [
                "BookModel",
                "BookCore",
                "BookData",
                .product(name: "NetworksInterface", package: "Networks"),
                .product(name: "TestSupport", package: "TestSupport")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
