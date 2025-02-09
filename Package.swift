// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "RSSBar", platforms: [.macOS(.v15)],
  products: [
    .executable(name: "RSSBar", targets: ["RSSBar"]),
    .library(name: "RSSKit", targets: ["RSSKit"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-http-types.git", from: "1.3.1"),
    .package(
      url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.3.3"),
  ],
  targets: [
    .executableTarget(
      name: "RSSBar",
      dependencies: [
        "RSSKit", .product(name: "HTTPTypes", package: "swift-http-types"),
        .product(name: "HTTPTypesFoundation", package: "swift-http-types"),
      ],
      resources: [
        .copy("Resources/icon.png"), .copy("Resources/icon.svg"),
        .copy("Resources/icon-with-banner.svg"),
        .copy("Resources/feed-forms.json"),
      ],
      linkerSettings: [
        .unsafeFlags([
          "-Xlinker", "-sectcreate",
          "-Xlinker", "__TEXT",
          "-Xlinker", "__info_plist",
          "-Xlinker", "Sources/RSSBar/Resources/Info.plist",
        ]),
        .unsafeFlags([
          "-Xlinker", "-sectcreate",
          "-Xlinker", "__TEXT",
          "-Xlinker", "__entitlements",
          "-Xlinker", "Sources/RSSBar/Resources/Entitlements.plist",
        ]),
      ]),
    .target(
      name: "RSSKit",
      dependencies: [
        .product(name: "HTTPTypes", package: "swift-http-types"),
        .product(name: "HTTPTypesFoundation", package: "swift-http-types"),
      ],
      resources: [
        .copy("Resources/atom.xsd"), .copy("Resources/json-feed.json"),
        .copy("Resources/rss2.xsd"),
      ]
    ),
    .testTarget(
      name: "RSSKitTests",
      dependencies: [
        "RSSKit", .product(name: "CustomDump", package: "swift-custom-dump"),
      ]),
  ])
