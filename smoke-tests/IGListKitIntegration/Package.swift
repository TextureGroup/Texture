// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "IGListKitIntegration",
    platforms: [
        .iOS(.v14),
    ],
    dependencies: [
        .package(path: "../../", traits: ["IGListKit"]),
        .package(url: "https://github.com/Instagram/IGListKit.git", from: "5.0.0"),
    ],
    targets: [
        .target(
            name: "IGListKitIntegration",
            dependencies: [
                .product(name: "AsyncDisplayKit", package: "Texture"),
                .product(name: "IGListKit", package: "IGListKit"),
            ]
        ),
    ]
)
