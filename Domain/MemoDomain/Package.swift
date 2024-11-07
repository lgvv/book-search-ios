// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MemoDomain",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "MemoModel", targets: ["MemoModel"]),
        .library(name: "MemoCore", targets: ["MemoCore"]),
        .library(name: "MemoData", targets: ["MemoData"])
    ],
    dependencies: [
        .package(path: "../../Domain/BookDomain"),
        .package(path: "../../Shared/DependencyResolver"),
        .package(path: "../../Shared/SharedFoundation"),
        .package(path: "../../Shared/Persistence"),
        .package(path: "../../Shared/TestSupport"),
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
        ),
        .target(
            name: "MemoData",
            dependencies: [
                .product(name: "PersistenceInterface", package: "Persistence"),
                "MemoModel",
                "MemoCore",
                .product(name: "BookModel", package: "BookDomain"),
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
