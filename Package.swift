// swift-tools-version:5.0
 import PackageDescription

 let package = Package(
      name: "Texture",
      platforms: [
          .iOS(.v9)
      ],
      products: [
          .library(name: "Texture", targets: ["Texture"])
      ],
      targets: [
         .target(
                name: "Texture",
                path: "Texture"
         )
      ]
  )
