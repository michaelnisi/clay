// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "Clay",
  platforms: [
//    .iOS(.v14), .macOS(.v10_15)
    .iOS(.v13)
  ],
  products: [
    .library(
      name: "Clay",
      targets: ["Clay"]),
  ],
  targets: [
    .target(
      name: "Clay",
      dependencies: []),
    .testTarget(
      name: "ClayTests",
      dependencies: ["Clay"]),
  ]
)
