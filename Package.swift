// swift-tools-version: 6.0
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

let package = Package(
    name: "Texture",
    products: [
        .library(
            name: "Texture",
            targets: ["Texture"]
        ),
    ],
    targets: [
        .target(
            name: "Texture",
            path: "Source",
            publicHeadersPath: ".",
            cSettings: headersSearchPath
        )
    ]
)
