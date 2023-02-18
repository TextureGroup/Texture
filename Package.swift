// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let headersSearchPath: [CSetting] = [
  .headerSearchPath("."),
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

let sharedDefines: [CSetting] = [
  // Disable "old" textnode by default for SPM
  // .define("AS_ENABLE_TEXTNODE", to: "0"),

  // PINRemoteImage always available for Texture
  // .define("AS_PIN_REMOTE_IMAGE", to: "1"),

  // always disabled
  .define("IG_LIST_COLLECTION_VIEW", to: "0")
]

func IGListKit(enabled: Bool) -> [CSetting] {
  let state: String = enabled ? "1" : "0"
  return [
    .define("AS_IG_LIST_KIT", to: state),
    .define("AS_IG_LIST_DIFF_KIT", to: state),
  ]
}

let package = Package(
  name: "Texture",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v10),
    .tvOS(.v10),
  ],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(
      name: "AsyncDisplayKit",
      type: .static,
      targets: ["AsyncDisplayKit"]
    )
  ],
  dependencies: [],
  targets: [
    .target(
      name: "AsyncDisplayKit",
      dependencies: [],
      path: "Source",
      publicHeadersPath: "include",
      cSettings: headersSearchPath + sharedDefines + IGListKit(enabled: false)
    )
  ],
  cLanguageStandard: .c11,
  cxxLanguageStandard: .cxx11
)
