import SwiftData
import SwiftUI

extension ModelContainer {
  static func initDefault() throws -> ModelContainer {
    // The bundle identifier is always included on build - crash if it's not
    let bundleID = Bundle.main.bundleIdentifier!
    let applicationSupport = try FileManager.default.url(
      for: .applicationSupportDirectory, in: .userDomainMask,
      appropriateFor: nil, create: true)

    let appSupportSubDirectory = applicationSupport.appending(
      path: bundleID, directoryHint: .isDirectory)

    let dataSubDirectory = appSupportSubDirectory.appending(
      components: "data", "v1", directoryHint: .isDirectory)

    try FileManager.default.createDirectory(
      at: dataSubDirectory, withIntermediateDirectories: true,
      attributes: nil)

    let configuration = ModelConfiguration(
      url: dataSubDirectory.appending(path: "data.sqlite"))

    return try ModelContainer(
      for: FeedGroup.self, Feed.self, FeedItem.self,
      configurations: configuration)
  }
}
