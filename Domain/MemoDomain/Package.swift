// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MemoDomain",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "MemoModel", targets: ["MemoModel"]),
        .library(name: "MemoCore", targets: ["MemoCore"])
    ],
    dependencies: [
        .package(path: "../../Domain/BookDomain"),
        .package(path: "../../Shared/DependencyResolver"),
        .package(path: "../../Shared/SharedFoundation"),
    ],
    targets: [
        .target(
            name: "MemoModel",
            dependencies: [
                .product(name: "BookModel", package: "BookDomain")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "MemoCore",
            dependencies: [
                "MemoModel",
                .product(name: "BookModel", package: "BookDomain"),
                .product(name: "DependencyResolver", package: "DependencyResolver"),
                .product(name: "SharedFoundation", package: "SharedFoundation")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
