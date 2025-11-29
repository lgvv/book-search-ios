// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "RemoteConfig",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "RemoteConfigInterface", targets: ["RemoteConfigInterface"]),
        .library(name: "RemoteConfig", targets: ["RemoteConfig"]),
    ],
    dependencies: [
        .package(path: "../Persistence"),
    ],
    targets: [
        .target(
            name: "RemoteConfigInterface",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "RemoteConfig",
            dependencies: [
                "RemoteConfigInterface",
                .product(name: "PersistenceInterface", package: "Persistence")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "RemoteConfigTests",
            dependencies: [
                "RemoteConfig",
                "RemoteConfigInterface"
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
