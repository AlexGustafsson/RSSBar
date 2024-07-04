import RSSKit
import SettingsAccess
import SwiftData
import SwiftUI
import os

func initializeModelContainer() throws -> ModelContainer {
  // The bundle identifier is always included on build - crash if it's not
  let bundleID = Bundle.main.bundleIdentifier!
  let applicationSupport = try FileManager.default.url(
    for: .applicationSupportDirectory, in: .userDomainMask,
    appropriateFor: nil, create: false)

  let appSupportSubDirectory = applicationSupport.appending(
    path: bundleID, directoryHint: .isDirectory)

  let dataSubDirectory = appSupportSubDirectory.appending(
    components: "data", "v1", directoryHint: .isDirectory)

  try FileManager.default.createDirectory(
    at: dataSubDirectory, withIntermediateDirectories: true, attributes: nil)

  let configuration = ModelConfiguration(
    url: dataSubDirectory.appending(path: "data.sqlite"))

  return try ModelContainer(
    for: FeedGroup.self, Feed.self, FeedItem.self,
    configurations: configuration)
}

func exportModelData(to directory: URL, modelContext: ModelContext) throws {
  let groups = try modelContext.fetch(FetchDescriptor<FeedGroup>())

  let encoder = JSONEncoder()
  encoder.outputFormatting = .prettyPrinted
  let data = try encoder.encode(groups)

  let dateFormatter = DateFormatter()
  dateFormatter.dateFormat = "yyy-MM-dd-HH-mm-ss"

  try data.write(
    to: directory.appending(
      component:
        "rssbar-export-\(dateFormatter.string(for: Date.now)!).json")
  )
}

func importModelData(from path: URL, modelContext: ModelContext) throws {
  let decoder = JSONDecoder()

  let groups = try decoder.decode(
    [FeedGroup].self, from: Data(contentsOf: path))

  // TODO: Due to SwiftData and relations, we can't really modify groups.feeds
  // without crashing (without an error). It seems like there's some meddling
  // where a context is necessary. If we just store the data immediately, then
  // we don't have an issue. But if we try to perform some modifications before
  // then we crash...
  // TODO: How do we best clean up group order? One way would be to try to
  // validate the orders and if they're bad, just replace with the index of the
  // group instead
  // for group in groups {
  //   // Clean up item order
  //   for (index, item) in group.feeds.enumerated() { item.order = index }
  // }

  try modelContext.transaction {
    // NOTE: Should coalesce delete on FeedGroup and Feed, but let's
    // make sure all potential dangling items are deleted as well
    try modelContext.delete(model: FeedGroup.self)
    try modelContext.delete(model: Feed.self)
    try modelContext.delete(model: FeedItem.self)

    for group in groups {
      modelContext.insert(group)
    }

    // Save is implicit
  }
}

func resetModelData(modelContext: ModelContext) throws {
  try modelContext.transaction {
    // NOTE: Should coalesce delete on FeedGroup and Feed, but let's
    // make sure all potential dangling items are deleted as well
    try modelContext.delete(model: FeedGroup.self)
    try modelContext.delete(model: Feed.self)
    try modelContext.delete(model: FeedItem.self)

    // Save is implicit
  }

  try DiskCache.shared.removeAll()
}
