// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "Texture",
    platforms: [
        .iOS(.v14),
        .tvOS(.v14)
    ],
    products: [
        .library(name: "Texture", targets: ["Texture"]),
        .library(name: "PINRemoteImage", targets: ["PINRemoteImage"]),
        .library(name: "IGListKit", targets: ["IGListKit"]),
        .library(name: "Yoga", targets: ["Yoga"]),
        .library(name: "TextNode2", targets: ["TextNode2"]),
        .library(name: "Video", targets: ["Video"]),
        .library(name: "MapKit", targets: ["MapKit"]),
        .library(name: "Photos", targets: ["Photos"]),
        .library(name: "AssetsLibrary", targets: ["AssetsLibrary"])
    ],
    dependencies: [
        .package(url: "https://github.com/pinterest/PINRemoteImage.git", from: "3.0.0"),
        .package(url: "https://github.com/Instagram/IGListKit.git", from: "4.0.0"),
        .package(url: "https://github.com/facebook/yoga.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "Texture",
            path: "Source",
            publicHeadersPath: "./",
            cxxSettings: [
                .define("CLANG_CXX_LANGUAGE_STANDARD", to: "c++11"),
                .define("CLANG_CXX_LIBRARY", to: "libc++")
            ]
        ),
        .target(
            name: "PINRemoteImage",
            dependencies: [
                "Texture",
                .product(name: "PINRemoteImage", package: "PINRemoteImage"),
                .product(name: "PINCache", package: "PINRemoteImage")
            ]
        ),
        .target(
            name: "IGListKit",
            dependencies: [
                "Texture",
                .product(name: "IGListKit", package: "IGListKit"),
                .product(name: "IGListDiffKit", package: "IGListKit")
            ]
        ),
        .target(
            name: "Yoga",
            dependencies: [
                "Texture",
                .product(name: "Yoga", package: "yoga")
            ],
            cSettings: [
                .define("YOGA", to: "1")
            ]
        ),
        .target(
            name: "TextNode2",
            dependencies: ["Texture"],
            cSettings: [
                .define("AS_ENABLE_TEXTNODE", to: "0")
            ]
        ),
        .target(
            name: "Video",
            dependencies: ["Texture"],
            cSettings: [
                .define("AS_USE_VIDEO", to: "1")
            ],
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("CoreMedia")
            ]
        ),
        .target(
            name: "MapKit",
            dependencies: ["Texture"],
            cSettings: [
                .define("AS_USE_MAPKIT", to: "1")
            ],
            linkerSettings: [
                .linkedFramework("CoreLocation"),
                .linkedFramework("MapKit")
            ]
        ),
        .target(
            name: "Photos",
            dependencies: ["Texture"],
            cSettings: [
                .define("AS_USE_PHOTOS", to: "1")
            ],
            linkerSettings: [
                .linkedFramework("Photos")
            ]
        ),
        .target(
            name: "AssetsLibrary",
            dependencies: ["Texture"],
            cSettings: [
                .define("AS_USE_ASSETS_LIBRARY", to: "1")
            ],
            linkerSettings: [
                .linkedFramework("AssetsLibrary")
            ]
        )
    ]
)
