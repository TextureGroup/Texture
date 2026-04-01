// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// MARK: - SPM Source Distribution
//
// This package provides source distribution for Texture with Swift Package Manager.
//
// Features:
//   - Core AsyncDisplayKit (all nodes, layout specs, TextNode2)
//   - PINRemoteImage integration
//   - IGListKit Swift wrapper (TextureIGListKitExtensions)
//
// IGListKit Integration:
//   The native Objective-C IGListKit API (IGListAdapter+AsyncDisplayKit, etc.) is disabled
//   because it requires conditional compilation flags (AS_IG_LIST_KIT=1) which create
//   Objective-C headers that cannot be bridged to Swift. Instead, use the Swift wrapper:
//
//   - Import: TextureIGListKitExtensions
//   - API: adapter.setCollectionNode(node) instead of adapter.setASDKCollectionNode(node)
//   - See Sources/TextureIGListKitExtensions/README.md for complete API mapping
//
// Other Limitations:
//   - Video/MapKit/Photos features not accessible (require framework linking)
//   - Old TextNode disabled (use modern TextNode2)

let package = Package(
    name: "Texture",
    platforms: [
        .iOS(.v14),
        .tvOS(.v14),
        .macCatalyst(.v13)
    ],
    products: [
        .library(
            name: "AsyncDisplayKit",
            targets: ["AsyncDisplayKit"]
        ),
        .library(
            name: "TextureIGListKitExtensions",
            targets: ["TextureIGListKitExtensions"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/pinterest/PINRemoteImage.git", from: "3.0.4"),
        .package(url: "https://github.com/Instagram/IGListKit", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "AsyncDisplayKit",
            dependencies: [
                "PINRemoteImage"
            ],
            path: "spm/Sources/AsyncDisplayKit",
            publicHeadersPath: "include",
            cSettings: [
                // Always available features
                .define("AS_PIN_REMOTE_IMAGE", to: "1"),

                // Disable old TextNode by default for SPM
                .define("AS_ENABLE_TEXTNODE", to: "0"),

                // IGListKit: Disabled for SPM (use TextureIGListKitExtensions instead)
                .define("AS_IG_LIST_KIT", to: "0"),
                .define("AS_IG_LIST_DIFF_KIT", to: "0"),

                // Disabled features
                .define("AS_USE_VIDEO", to: "0"),           // Not accessible from Swift via SPM
                .define("AS_USE_MAPKIT", to: "0"),          // Not accessible from Swift via SPM
                .define("AS_USE_PHOTOS", to: "0"),          // Partially accessible from Swift via SPM
                .define("AS_USE_ASSETS_LIBRARY", to: "0"),  // Deprecated iOS 9.0, use Photos framework

                // Always disabled for SPM
                .define("IG_LIST_COLLECTION_VIEW", to: "0"),

                // Header search paths
                .headerSearchPath("."),
                .headerSearchPath("include/AsyncDisplayKit"),  // For quoted-style imports
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
                .headerSearchPath("tvOS")
            ],
            cxxSettings: [
                .headerSearchPath("."),
                .headerSearchPath("include/AsyncDisplayKit"),  // For quoted-style imports
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
                .headerSearchPath("tvOS")
            ],
            linkerSettings: [
                .linkedLibrary("c++")
                // Note: Video/MapKit/Photos frameworks not linked by default
                // These features are not accessible from Swift via SPM due to conditional compilation
                // Use CocoaPods or Carthage if you need these features, or use Objective-C code
            ]
        ),
        .target(
            name: "TextureIGListKitExtensions",
            dependencies: [
                "AsyncDisplayKit",
                .product(name: "IGListKit", package: "IGListKit"),
                .product(name: "IGListDiffKit", package: "IGListKit")
            ],
            path: "Sources/TextureIGListKitExtensions",
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                // Use Swift 5 mode because this is a wrapper around Objective-C code
                // that lacks Swift Concurrency annotations. When AsyncDisplayKit adds
                // proper @MainActor annotations, we can migrate to Swift 6 mode.
                .swiftLanguageMode(.v5)
            ]
        )
    ],
    cLanguageStandard: .c11,
    cxxLanguageStandard: .cxx20
)
