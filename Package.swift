// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let headersSearchPath: [CSetting] = [.headerSearchPath("."),
                                     .headerSearchPath("Base"),
                                     .headerSearchPath("Debug"),
                                     .headerSearchPath("Details"),
                                     .headerSearchPath("Details/Transactions"),
                                     .headerSearchPath("Layout"),
                                     .headerSearchPath("Private"),
                                     .headerSearchPath("Private/Layout"),
                                     .headerSearchPath("Private/TextExperiment/Component"),
                                     .headerSearchPath("Private/TextExperiment/String"),
                                     .headerSearchPath("Private/TextExperiment/Utility"),
                                     .headerSearchPath("TextKit"),
                                     .headerSearchPath("tvOS"),]

let package = Package(
    name: "Texture",
    platforms: [
             .macOS(.v10_15),
             .iOS(.v10),
             .tvOS(.v10)
         ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "AsynkDisplayKit",
            type: .static,
            targets: ["AsynkDisplayKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/3a4oT/PINRemoteImage.git", .branch("spm")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "AsynkDisplayKit",
            dependencies: ["PINRemoteImage"],
            path: "Source",
            exclude: ["Info.plist"],
            publicHeadersPath: "include",
            cSettings: headersSearchPath + [
                // Disable "old" textnode by default for SPM
                .define("AS_ENABLE_TEXTNODE", to: "0"),
                
                 // extra IGListKit
                .define("AS_IG_LIST_KIT", to: "0"),
                .define("AS_IG_LIST_DIFF_KIT", to: "0"),
                // always disabled
                .define("IG_LIST_COLLECTION_VIEW", to: "0"),
            ]
        ),
    ],
    cLanguageStandard: .gnu99,
    cxxLanguageStandard: .cxx11
)
