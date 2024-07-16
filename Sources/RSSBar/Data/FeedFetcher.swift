import RSSKit
import SwiftData
import SwiftUI
import os

enum FeedFetchCondition {
  case unconditional
  case outdated
}

private let logger = Logger(
  subsystem: Bundle.main.bundleIdentifier!, category: "Data")

@ModelActor actor FeedFetcher {
  func fetchFeeds(if condition: FeedFetchCondition = .outdated) async throws {
    let feedIds = try modelContext.feedIds()

    for chunk in feedIds.chunked(into: 5) {
      await withThrowingTaskGroup(of: Void.self) { taskGroup in
        for feedId in chunk {
          taskGroup.addTask(operation: {
            try await self.fetchFeed(feedId: feedId, if: condition)
          })
        }
      }
    }
  }

  func fetchFeed(
    feedId: PersistentIdentifier,
    if condition: FeedFetchCondition = .outdated
  ) async throws {
    guard
      let feed =
        try self.modelContext.fetch(feedId, for: Feed.self)
    else {
      return
    }

    if condition == .outdated {
      if feed.lastUpdated != nil
        && feed.lastUpdated!.distance(to: Date()) <= 1 * 60 * 60
      {
        return
      }
    }

    logger.debug(
      "Updating \(feed.name, privacy: .public)@\(feed.url.absoluteString, privacy: .public)"
    )
    do {
      let result = try await RSSFeed(contentsOf: feed.url)
      for item in result.entries {
        let id = UUID.v8(withHash: "\(feed.id):\(item.id)")

        let oldItem = feed.items.first(where: {
          $0.id == id
        })

        let newItem = FeedItem(
          id: id,
          title: item.title ?? item.summary ?? "Feed item",
          date: item.updated,
          read: oldItem?.read,
          url: item.links.first
        )
        // IMPORTANT! We seem to need to set up this relationship
        // before saving the data, otherwise we get weird crashes
        // without any helpful errors
        newItem.feed = feed
        feed.items.append(newItem)
      }
      feed.lastUpdated = Date()
      logger.debug(
        "Feed updated \(feed.name, privacy: .public)@\(feed.url.absoluteString, privacy: .public): \(result.entries.count)"
      )
      try modelContext.save()
    } catch {
      logger.debug(
        "Failed to update feed \(feed.name, privacy: .public)@\(feed.url.absoluteString, privacy: .public): \(error)"
      )
    }
  }
}
