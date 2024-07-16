import SwiftData
import SwiftUI
import os

private let logger = Logger(
  subsystem: Bundle.main.bundleIdentifier!, category: "Database")

extension Database {
  public func moveFeedInGroup(
    groupId: PersistentIdentifier, from: IndexSet, to: Int
  ) async throws {
    logger.debug("Moving feed in group: \(groupId.description(), privacy: .public) from \(from, privacy: .public) to \(to, privacy: .public)")
    // let group = try await self.fetch(groupId) as! FeedGroup

    // // Let's update the order of all items to make sure the values never leave
    // // the bounds of the array. SwiftData does not guarantee that the order of
    // // items are kept
    // group.feeds.sort(by: { $0.order < $1.order })
    // let x = group.feeds[]
    // // group.feeds.move(fromOffsets: from, toOffset: to)
    // for (index, item) in group.feeds.enumerated() {
    //   item.order = index
    // }
  }

  public func moveGroup(groupId: PersistentIdentifier, positions: Int)
    async throws
  {
    logger.debug("Moving group: \(groupId.description(), privacy: .public) \(positions, privacy: .public) positions")
    var groups = try await self.fetch(FetchDescriptor<FeedGroup>())
      .sorted(by: { $0.order < $1.order })
    let groupIndex = groups.firstIndex { $0.id == groupId }!
    groups.move(
      fromOffsets: IndexSet(integer: groupIndex),
      toOffset: groupIndex + positions)
    for (index, item) in groups.enumerated() {
      item.order = index
    }
  }

  public func countUnreadFeeds() async throws -> Int {
    logger.debug("Counting unread feeds")
    let descriptor = FetchDescriptor<FeedItem>(
      predicate: #Predicate { $0.read == nil })
    let count = try await self.fetchCount(descriptor)
    return count
  }

  public func markAllAsRead(feedId: PersistentIdentifier) async throws {
    logger.debug("Marking feed as read: \(feedId.description(), privacy: .public)")
    guard let feed = try await self.fetch(feedId, for: Feed.self) else {
      return
    }
    for item in feed.items {
      if item.read == nil {
        item.read = Date()
      }
    }
  }

  public func markAllAsRead() async throws {
    logger.debug("Marking all feeds as read")
    let feeds = try await self.fetch(FetchDescriptor<FeedItem>())
    for item in feeds {
      if item.read == nil {
        item.read = Date()
      }
    }
  }

  public func markAsRead(feedItemId: PersistentIdentifier) async throws {
    logger.debug("Marking feed item as read: \(feedItemId.description(), privacy: .public)")
    guard let item = try await self.fetch(feedItemId, for: FeedItem.self) else {
      return
    }
    item.read = Date()
  }

  public func addFeed(groupId: PersistentIdentifier, feed: Feed) async throws {
    logger.debug("Adding feed to group: \(groupId.description(), privacy: .public)")
    guard let group = try await self.fetch(groupId, for: FeedGroup.self)  else {
      return
    }
    group.feeds.sort(by: { $0.order < $1.order })
    group.feeds.append(feed)
    for (index, item) in group.feeds.enumerated() { item.order = index }
  }

  public func deleteFeed(feedId: PersistentIdentifier) async throws {
    logger.debug("Deleting feed: \(feedId.description(), privacy: .public)")
    guard let feed = try await self.fetch(feedId, for: Feed.self) else {
      return
    }
    feed.group!.feeds = feed.group!.feeds.filter({ $0.id != feedId })
      .sorted(by: { $0.order < $1.order }).enumerated()
      .map({
        $0.element.order = $0.offset
        return $0.element
      })

    await self.delete(feed)
  }

  public func addGroup(name: String) async throws {
    logger.debug("Adding group")
    let groupCount = try await self.fetchCount(FetchDescriptor<FeedGroup>())
    let group = FeedGroup(name: name)
    group.order = groupCount
    await self.insert(group)
  }

  public func clearHistory(feedId: PersistentIdentifier) async throws {
    logger.debug("Clearing history for feed: \(feedId.description(), privacy: .public)")
    guard let feed = try await self.fetch(feedId, for: Feed.self) else {
      return
    }
    for item in feed.items { item.read = nil }
  }

  public func clearItems(feedId: PersistentIdentifier) async throws {
    logger.debug("Clearing items for feed: \(feedId.description(), privacy: .public)")
    guard let feed = try await self.fetch(feedId, for: Feed.self) else {
      return
    }
    for item in feed.items {
      await self.delete(item)
    }
    feed.items.removeAll()
  }

  public func exportData(to fileName: URL) async throws {
    logger.debug("Exporting data")
    let groups = try await self.fetch(FetchDescriptor<FeedGroup>())

    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data = try encoder.encode(groups)

    try data.write(
      to: fileName
    )
  }

  public func importData(from path: URL) async throws {
    logger.debug("Importing data")
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

    try await self.transaction { modelContext in
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

  public func reset() async throws {
    logger.debug("Resetting database")
    try await self.transaction { modelContext in
      // NOTE: Should coalesce delete on FeedGroup and Feed, but let's
      // make sure all potential dangling items are deleted as well
      try modelContext.delete(model: FeedGroup.self)
      try modelContext.delete(model: Feed.self)
      try modelContext.delete(model: FeedItem.self)

      // Save is implicit
    }
  }

  public func changeFeedGroup(
    feedId: PersistentIdentifier, toGroup groupId: PersistentIdentifier,
    at targetIndex: Int?
  ) async throws {
    logger.debug("Changing feed group for \(feedId.description(), privacy: .public) to \(groupId.description(), privacy: .public)")
    guard let feed = try await self.fetch(feedId, for: Feed.self) else {
      return
    }
    guard let targetGroup = try await self.fetch(groupId, for: FeedGroup.self) else {
      return
    }

    // Remove from the current group
    feed.group!.feeds = feed.group!.feeds.filter({ $0.id != feedId })
      .sorted(by: { $0.order < $1.order }).enumerated()
      .map({
        $0.element.order = $0.offset
        return $0.element
      })

    // Sort items to ensure insert order
    targetGroup.feeds.sort(by: { $0.order < $1.order })

    // Add to new group
    if targetIndex == nil {
      targetGroup.feeds.append(feed)
    } else {
      targetGroup.feeds.insert(feed, at: targetIndex!)
    }

    // Update order
    for (index, item) in targetGroup.feeds.enumerated() {
      item.order = index
    }
  }

  public func feedIds() async throws -> [PersistentIdentifier] {
    logger.debug("Fetching feed ids")
    return try await SharedDatabase.shared.database
        .fetch(FetchDescriptor<Feed>())
        .map({
          $0.persistentModelID
        })
  }
}
