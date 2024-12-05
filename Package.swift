// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "Texture",
    platforms: [
        .iOS(.v14),  // Set iOS deployment target to match the podspec
        .tvOS(.v14)
    ],
    products: [
        .library(
            name: "Texture",
            targets: ["Texture"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/pinterest/PINRemoteImage.git", from: "3.0.0"),
        .package(url: "https://github.com/Instagram/IGListKit.git", from: "4.0.0"),
        .package(url: "https://github.com/facebook/yoga.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "Texture",
            dependencies: [
                .target(name: "Core"),
                .product(name: "PINRemoteImage", package: "PINRemoteImage"),
                .product(name: "IGListKit", package: "IGListKit"),
                .product(name: "Yoga", package: "yoga")
            ],
            path: "Source",
            exclude: [
                "AsyncDisplayKit+Tips",
                "Examples",
                "Tests"
            ],
            publicHeadersPath: "AsyncDisplayKit",
            cSettings: [
                .headerSearchPath("Source"),
                .headerSearchPath("Source/Details"),
                .headerSearchPath("Source/Layout"),
                .headerSearchPath("Source/Base"),
                .headerSearchPath("Source/Debug"),
                .headerSearchPath("Source/TextKit"),
                .headerSearchPath("Source/TextExperiment"),
                .define("USE_TEXTURE")
            ]
        ),
        .target(
            name: "Core",
            dependencies: [],
            path: "Source/Core"
        ),
        .testTarget(
            name: "TextureTests",
            dependencies: ["Texture"],
            path: "Tests"
        ),
        .target(
            name: "PINRemoteImage",
            dependencies: [
                .product(name: "PINRemoteImage", package: "PINRemoteImage")
            ],
            path: "Source/PINRemoteImage"
        ),
        .target(
            name: "IGListKit",
            dependencies: [
                .product(name: "IGListKit", package: "IGListKit")
            ],
            path: "Source/IGListKit"
        ),
        .target(
            name: "Yoga",
            dependencies: [
                .product(name: "Yoga", package: "yoga")
            ],
            path: "Source/Yoga"
        )
    ],
    swiftLanguageVersions: [.v5]
)
