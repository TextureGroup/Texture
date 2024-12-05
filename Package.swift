// swift-tools-version:5.7
import PackageDescription

let headersSearchPath: [CSetting] = [.headerSearchPath("."),
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
                                     .headerSearchPath("tvOS"),]

let sharedDefines: [CSetting] = [
                                // Disable "old" textnode by default for SPM
                                .define("AS_ENABLE_TEXTNODE", to: "0"),
    
                                // PINRemoteImage always available for Texture
                                .define("AS_PIN_REMOTE_IMAGE", to: "1"),
                                
                                // always disabled
                                .define("IG_LIST_COLLECTION_VIEW", to: "0"),]

let package = Package(
    name: "AsyncDisplayKit",
    platforms: [
        .iOS(.v8)
    ],
    products: [
        .library(
            name: "AsyncDisplayKit",
            targets: ["AsyncDisplayKit"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/pinterest/PINRemoteImage.git", .branch("master")),
    ],
    targets: [
        .target(
            name: "AsyncDisplayKit",
            dependencies: ["PINRemoteImage"],
            path: "Source"
        )
    ]
)
