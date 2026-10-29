// swift-tools-version:5.5

import PackageDescription

let headerSearchPaths: [PackageDescription.CSetting] = [
    .headerSearchPath("."),
    .headerSearchPath("include"),
    .headerSearchPath("include/AsyncDisplayKit"),
    .headerSearchPath("Base"),
    .headerSearchPath("Debug"),
    .headerSearchPath("Details"),
    .headerSearchPath("Details/Transactions"),
    .headerSearchPath("Layout"),
    .headerSearchPath("Private"),
    .headerSearchPath("Private/Layout"),
    .headerSearchPath("TextExperiment/Component"),
    .headerSearchPath("TextExperiment/String"),
    .headerSearchPath("TextExperiment/Utility"),
    .headerSearchPath("TextKit"),
    .headerSearchPath("tvOS"),
]

let featureDefines: [PackageDescription.CSetting] = [
    .define("AS_USE_VIDEO", to: "1"),
    .define("AS_USE_MAPKIT", to: "0"),
    .define("AS_USE_PHOTOS", to: "0"),
    .define("AS_USE_ASSETS_LIBRARY", to: "0"),
    .define("AS_IG_LIST_KIT", to: "0"),
    .define("AS_IG_LIST_DIFF_KIT", to: "0"),
    .define("IG_LIST_COLLECTION_VIEW", to: "0"),
]

let cxxHeaderSearchPaths: [PackageDescription.CXXSetting] = [
    .headerSearchPath("."),
    .headerSearchPath("include"),
    .headerSearchPath("include/AsyncDisplayKit"),
    .headerSearchPath("Base"),
    .headerSearchPath("Debug"),
    .headerSearchPath("Details"),
    .headerSearchPath("Details/Transactions"),
    .headerSearchPath("Layout"),
    .headerSearchPath("Private"),
    .headerSearchPath("Private/Layout"),
    .headerSearchPath("TextExperiment/Component"),
    .headerSearchPath("TextExperiment/String"),
    .headerSearchPath("TextExperiment/Utility"),
    .headerSearchPath("TextKit"),
    .headerSearchPath("tvOS"),
]

let cxxFeatureDefines: [PackageDescription.CXXSetting] = [
    .define("AS_USE_VIDEO", to: "1"),
    .define("AS_USE_MAPKIT", to: "0"),
    .define("AS_USE_PHOTOS", to: "0"),
    .define("AS_USE_ASSETS_LIBRARY", to: "0"),
    .define("AS_IG_LIST_KIT", to: "0"),
    .define("AS_IG_LIST_DIFF_KIT", to: "0"),
    .define("IG_LIST_COLLECTION_VIEW", to: "0"),
]

let package = Package(
    name: "Texture",
    platforms: [
        .iOS(.v14),
        .tvOS(.v14),
    ],
    products: [
        .library(name: "AsyncDisplayKit", targets: ["AsyncDisplayKit"]),
    ],
    targets: [
        .target(
            name: "AsyncDisplayKit",
            dependencies: [],
            path: "Source",
            exclude: [
                "Info.plist",
            ],
            publicHeadersPath: "include",
            cSettings: headerSearchPaths + featureDefines,
            cxxSettings: cxxHeaderSearchPaths + cxxFeatureDefines,
            linkerSettings: [
                .linkedLibrary("c++"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("CoreMedia"),
                .linkedFramework("UIKit"),
                .linkedFramework("Foundation"),
                .linkedFramework("QuartzCore"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("CoreText"),
            ]
        ),
    ],
    cLanguageStandard: .c11,
    cxxLanguageStandard: .cxx11
)
