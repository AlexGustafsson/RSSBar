// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "RSSBar",
  platforms: [.macOS(.v14)],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .executable(
      name: "RSSBar",
      targets: ["RSSBar"]),
    .library(
      name: "RSSKit",
      targets: ["RSSKit"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-http-types.git", from: "1.1.0"
    ),
    .package(
      url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.0.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .executableTarget(
      name: "RSSBar"
    ),
    .target(
      name: "RSSKit",
      dependencies: [
        .product(name: "HTTPTypes", package: "swift-http-types"),
        .product(name: "HTTPTypesFoundation", package: "swift-http-types"),
      ],
      resources: [
        .copy("Resources/atom.xsd"),
        .copy("Resources/rss2.xsd"),
      ]
    ),
    .testTarget(
      name: "RSSKitTests",
      dependencies: [
        "RSSKit",
        .product(name: "CustomDump", package: "swift-custom-dump"),
      ]),
  ]
)
