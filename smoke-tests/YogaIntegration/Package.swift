// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "YogaIntegration",
    platforms: [
        .iOS(.v14),
    ],
    dependencies: [
        .package(path: "../../", traits: ["Yoga"]),
    ],
    targets: [
        .target(
            name: "YogaIntegration",
            dependencies: [
                .product(name: "AsyncDisplayKit", package: "Texture"),
            ]
        ),
    ]
)
