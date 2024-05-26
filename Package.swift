// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "RSSBar",
  platforms: [.macOS(.v14)],
  products: [
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
    .executableTarget(
      name: "RSSBar",
      dependencies: [
        .product(name: "HTTPTypes", package: "swift-http-types"),
        .product(name: "HTTPTypesFoundation", package: "swift-http-types"),
      ],
      resources: [
        .copy("Resources/icon.png")
      ]
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
