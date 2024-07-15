import SwiftData
import SwiftUI
import os

public struct SharedDatabase {
  public static let shared: SharedDatabase = .init()

  public let modelContainer: ModelContainer
  public let database: any Database

  private init(
    modelContainer: ModelContainer? = nil,
    database: (any Database)? = nil
  ) {
    self.modelContainer =
      modelContainer
      ?? {
        // The bundle identifier is always included on build - crash if it's not
        let bundleID = Bundle.main.bundleIdentifier!
        let applicationSupport = try! FileManager.default.url(
          for: .applicationSupportDirectory, in: .userDomainMask,
          appropriateFor: nil, create: false)

        let appSupportSubDirectory = applicationSupport.appending(
          path: bundleID, directoryHint: .isDirectory)

        let dataSubDirectory = appSupportSubDirectory.appending(
          components: "data", "v1", directoryHint: .isDirectory)

        try! FileManager.default.createDirectory(
          at: dataSubDirectory, withIntermediateDirectories: true,
          attributes: nil)

        let configuration = ModelConfiguration(
          url: dataSubDirectory.appending(path: "data.sqlite"))

        return try! ModelContainer(
          for: FeedGroup.self, Feed.self, FeedItem.self,
          configurations: configuration)
      }()

    self.database =
      database ?? BackgroundDatabase(modelContainer: self.modelContainer)
  }
}
