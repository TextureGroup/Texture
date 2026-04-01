// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SPMBasic",
    platforms: [
        .iOS(.v14),
        .macCatalyst(.v13)
    ],
    products: [
        .library(
            name: "SPMBasic",
            targets: ["SPMBasic"]
        )
    ],
    dependencies: [
        .package(path: "../..")
    ],
    targets: [
        .target(
            name: "SPMBasic",
            dependencies: [
                .product(name: "AsyncDisplayKit", package: "Texture")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "SPMBasicTests",
            dependencies: ["SPMBasic"],
            path: "Tests"
        )
    ]
)
