// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "Clay",
  platforms: [
    .iOS(.v14), .macOS(.v10_15)
  ],
  products: [
    .library(
      name: "Clay",
      targets: ["Clay"]),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),
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
