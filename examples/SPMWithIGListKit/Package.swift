// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "SPMWithIGListKit",
    platforms: [
        .iOS(.v14),
        .macCatalyst(.v13)
    ],
    products: [
        .library(
            name: "SPMWithIGListKit",
            targets: ["SPMWithIGListKit"]
        )
    ],
    dependencies: [
        .package(
            path: "../.."
        )
    ],
    targets: [
        .target(
            name: "SPMWithIGListKit",
            dependencies: [
                .product(name: "AsyncDisplayKit", package: "Texture"),
                .product(name: "TextureIGListKitExtensions", package: "Texture")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "SPMWithIGListKitTests",
            dependencies: ["SPMWithIGListKit"],
            path: "Tests"
        )
    ]
)
