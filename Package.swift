// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "RSSBar", platforms: [.macOS(.v14)],
  products: [
    .executable(name: "RSSBar", targets: ["RSSBar"]),
    .library(name: "RSSKit", targets: ["RSSKit"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-http-types.git", from: "1.1.0"),
    .package(
      url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.0.0"),
    .package(url: "https://github.com/orchetect/SettingsAccess", from: "1.4.0"),
  ],
  targets: [
    .executableTarget(
      name: "RSSBar",
      dependencies: [
        "RSSKit", .product(name: "HTTPTypes", package: "swift-http-types"),
        .product(name: "HTTPTypesFoundation", package: "swift-http-types"),
        .product(name: "SettingsAccess", package: "SettingsAccess"),
      ],
      resources: [
        .copy("Resources/icon.png"), .copy("Resources/icon.svg"),
        .copy("Resources/icon-with-banner.svg"),
        .copy("Resources/feed-forms.json"),
      ],
      swiftSettings: [
        .enableExperimentalFeature("StrictConcurrency=minimal")
    ],
      linkerSettings: [
        .unsafeFlags([
          "-Xlinker", "-sectcreate", "-Xlinker", "__TEXT", "-Xlinker",
          "__info_plist", "-Xlinker", "Sources/RSSBar/Resources/Info.plist",
        ])
      ]),
    .target(
      name: "RSSKit",
      dependencies: [
        .product(name: "HTTPTypes", package: "swift-http-types"),
        .product(name: "HTTPTypesFoundation", package: "swift-http-types"),
      ], resources: [.copy("Resources/atom.xsd"), .copy("Resources/rss2.xsd")],
      swiftSettings: [
        .enableExperimentalFeature("StrictConcurrency=complete")
    ]
      ),
    .testTarget(
      name: "RSSKitTests",
      dependencies: [
        "RSSKit", .product(name: "CustomDump", package: "swift-custom-dump"),
      ]),
  ])
