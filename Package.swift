// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Texture",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v14),
        .tvOS(.v14),
    ],
    products: [
        .library(
            name: "AsyncDisplayKit",
            type: .static,
            targets: [
                "AsyncDisplayKit"
            ]
        ),
    ],
    traits: [
        Trait(name: "IGListKit", description: "Include IGListKit support"),
        Trait(name: "Yoga", description: "Include Yoga support"),
    ],
    dependencies: [
        .package(url: "https://github.com/Instagram/IGListKit.git", from: "5.0.0"),
        .package(url: "https://github.com/facebook/yoga.git", from: "3.1.0"),
        .package(url: "https://github.com/pinterest/PINRemoteImage.git", from: "3.0.4"),
    ],
    targets: [
        .target(
            name: "AsyncDisplayKit",
            dependencies: [
                .product(name: "PINRemoteImage", package: "PINRemoteImage"),
                .product(name: "IGListKit", package: "IGListKit", condition: .when(traits: ["IGListKit"])),
                .product(name: "IGListDiffKit", package: "IGListKit", condition: .when(traits: ["IGListKit"])),
                .product(name: "yoga", package: "yoga", condition: .when(traits: ["Yoga"])),
            ],
            path: "Source/Texture",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("Private"),
                .headerSearchPath("Private/Layout"),
                .define("AS_ENABLE_TEXTNODE", to: "1"),
                .define("AS_USE_VIDEO", to: "1"),
                .define("AS_USE_MAPKIT", to: "1"),
                .define("AS_USE_PHOTOS", to: "1"),
                .define("AS_USE_ASSETS_LIBRARY", to: "1"),
                .define("YOGA", to: "1", .when(traits: ["Yoga"])),
                .define("AS_IG_LIST_KIT", to: "1", .when(traits: ["IGListKit"])),
                .define("AS_IG_LIST_DIFF_KIT", to: "1", .when(traits: ["IGListKit"])),
            ],
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("CoreMedia"),
                .linkedFramework("CoreLocation"),
                .linkedFramework("MapKit"),
                .linkedFramework("Photos"),
                .linkedFramework("AssetsLibrary"),
            ]
        ),
    ],
    cLanguageStandard: .c11,
    cxxLanguageStandard: .cxx11
)