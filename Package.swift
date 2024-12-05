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
        )
    ]
)
