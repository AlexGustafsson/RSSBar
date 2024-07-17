import SwiftData
import SwiftUI
import os

private let logger = Logger(
  subsystem: Bundle.main.bundleIdentifier!, category: "Data")

extension ModelContext {
  public func fetch<T>(_ id: PersistentIdentifier, for: T.Type) throws -> T?
  where T: PersistentModel {
    if let registered: T = self.registeredModel(for: id) {
      return registered
    }

    let fetchDescriptor = FetchDescriptor<T>(
      predicate: #Predicate {
        $0.persistentModelID == id
      })

    return try self.fetch(fetchDescriptor).first
  }
}

extension ModelContext {
  func moveFeedInGroup(
    groupId: PersistentIdentifier, from: IndexSet, to: Int
  ) throws {
    logger.debug(
      "Moving feed in group: \(groupId.description(), privacy: .public) from \(from, privacy: .public) to \(to, privacy: .public)"
    )

    guard let group = try self.fetch(groupId, for: FeedGroup.self) else {
      return
    }

    // Let's update the order of all items to make sure the values never leave
    // the bounds of the array. SwiftData does not guarantee that the order of
    // items are kept
    var feeds = group.feeds.sorted(by: { $0.order < $1.order })
    feeds.move(fromOffsets: from, toOffset: to)
    for (index, item) in feeds.enumerated() {
      item.order = index
    }
    group.feeds = feeds
  }

  func moveGroup(groupId: PersistentIdentifier, positions: Int)
    throws
  {
    logger.debug(
      "Moving group: \(groupId.description(), privacy: .public) \(positions, privacy: .public) positions"
    )
    var groups = try self.fetch(FetchDescriptor<FeedGroup>())
      .sorted(by: { $0.order < $1.order })
    let groupIndex = groups.firstIndex { $0.id == groupId }!
    groups.move(
      fromOffsets: IndexSet(integer: groupIndex),
      toOffset: groupIndex + positions)
    for (index, item) in groups.enumerated() {
      item.order = index
    }
  }

  func countUnreadFeeds() throws -> Int {
    logger.debug("Counting unread feeds")
    let descriptor = FetchDescriptor<FeedItem>(
      predicate: #Predicate { $0.read == nil })
    let count = try self.fetchCount(descriptor)
    return count
  }

  func markAllAsRead(feedId: PersistentIdentifier) throws {
    logger.debug(
      "Marking feed as read: \(feedId.description(), privacy: .public)")
    guard let feed = try self.fetch(feedId, for: Feed.self) else {
      return
    }
    for item in feed.items {
      if item.read == nil {
        item.read = Date()
      }
    }
  }

  func markAllAsRead() throws {
    logger.debug("Marking all feeds as read")
    let feeds = try self.fetch(FetchDescriptor<FeedItem>())
    for item in feeds {
      if item.read == nil {
        item.read = Date()
      }
    }
  }

  func markAsRead(feedItemId: PersistentIdentifier) throws {
    logger.debug(
      "Marking feed item as read: \(feedItemId.description(), privacy: .public)"
    )
    guard let item = try self.fetch(feedItemId, for: FeedItem.self)
    else {
      return
    }
    item.read = Date()
  }

  func addFeed(groupId: PersistentIdentifier, feed: Feed) throws {
    logger.debug(
      "Adding feed to group: \(groupId.description(), privacy: .public)")
    guard let group = try self.fetch(groupId, for: FeedGroup.self)
    else {
      return
    }
    var feeds = group.feeds.sorted(by: { $0.order < $1.order })
    feeds.append(feed)
    for (index, item) in feeds.enumerated() { item.order = index }
    group.feeds = feeds
  }

  func deleteFeed(feedId: PersistentIdentifier) throws {
    logger.debug("Deleting feed: \(feedId.description(), privacy: .public)")
    guard let feed = try self.fetch(feedId, for: Feed.self) else {
      return
    }
    feed.group!.feeds = feed.group!.feeds.filter({ $0.id != feedId })
      .sorted(by: { $0.order < $1.order }).enumerated()
      .map({
        $0.element.order = $0.offset
        return $0.element
      })

    self.delete(feed)
  }

  func addGroup(name: String) throws {
    logger.debug("Adding group")
    let groupCount = try self.fetchCount(
      FetchDescriptor<FeedGroup>())
    let group = FeedGroup(name: name)
    group.order = groupCount
    self.insert(group)
  }

  func clearHistory(feedId: PersistentIdentifier) throws {
    logger.debug(
      "Clearing history for feed: \(feedId.description(), privacy: .public)")
    guard let feed = try self.fetch(feedId, for: Feed.self) else {
      return
    }
    for item in feed.items { item.read = nil }
  }

  func clearItems(feedId: PersistentIdentifier) throws {
    logger.debug(
      "Clearing items for feed: \(feedId.description(), privacy: .public)")
    guard let feed = try self.fetch(feedId, for: Feed.self) else {
      return
    }
    for item in feed.items {
      self.delete(item)
    }
    feed.items.removeAll()
  }

  func exportData(to fileName: URL) throws {
    logger.debug("Exporting data")
    let groups = try self.fetch(FetchDescriptor<FeedGroup>())

    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data = try encoder.encode(groups)

    try data.write(
      to: fileName
    )
  }

  func importData(from path: URL) throws {
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

    // NOTE: Should cascade delete on FeedGroup and Feed, but it doesn't always
    // seem to work. Let's make sure all potential dangling items are deleted as
    // well. We need to save between each change as SwiftData will cause a crash
    // if we try to delete a deleted model. This makes it impossible to use a
    // transaction in a meaningful way

    try self.reset()
    for group in groups {
      self.insert(group)
    }
    try self.save()
  }

  func reset() throws {
    logger.debug("Resetting data")

    // NOTE: Should cascade delete on FeedGroup and Feed, but it doesn't always
    // seem to work. Let's make sure all potential dangling items are deleted as
    // well. We need to save between each change as SwiftData will cause a crash
    // if we try to delete a deleted model.

    try self.delete(model: FeedGroup.self)
    try self.save()

    try self.delete(model: Feed.self)
    try self.save()

    try self.delete(model: FeedItem.self)
    try self.save()
  }

  func changeFeedGroup(
    feedId: PersistentIdentifier, toGroup groupId: PersistentIdentifier,
    at targetIndex: Int?
  ) throws {
    logger.debug(
      "Changing feed group for \(feedId.description(), privacy: .public) to \(groupId.description(), privacy: .public)"
    )
    guard let feed = try self.fetch(feedId, for: Feed.self) else {
      return
    }
    guard let targetGroup = try self.fetch(groupId, for: FeedGroup.self) else {
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
    var feeds = targetGroup.feeds.sorted(by: { $0.order < $1.order })

    // Add to new group
    if targetIndex == nil {
      feeds.append(feed)
    } else {
      feeds.insert(feed, at: targetIndex!)
    }

    // Update order
    for (index, item) in feeds.enumerated() {
      item.order = index
    }

    targetGroup.feeds = feeds
  }

  func feedIds() throws -> [PersistentIdentifier] {
    logger.debug("Fetching feed ids")
    return try self.fetch(FetchDescriptor<Feed>())
      .map({
        $0.persistentModelID
      })
  }
}
