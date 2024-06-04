import Foundation
import SwiftData

enum FeedUpdateInterval: Codable {
  case `default`
  case hourly
  case daily
  case weekly
  case monthly
}

@Model class FeedGroup: Identifiable {
  @Attribute(.unique) var name: String
  @Relationship(deleteRule: .cascade, inverse: \Feed.group) var feeds: [Feed] =
    []
  var index: Int?

  init(name: String) {
    self.name = name
  }

  convenience init(name: String, feeds: [Feed] = []) {
    self.init(name: name)
    self.feeds = feeds
  }

  var id: String {
    return self.name
  }
}

@Model class Feed: Identifiable {
  @Attribute(.unique) var name: String
  @Attribute(.unique) var url: URL

  @Relationship(deleteRule: .cascade) var items: [FeedItem] = []
  var updateInterval: FeedUpdateInterval = FeedUpdateInterval.default
  var lastUpdated: Date?

  var group: FeedGroup?

  init(name: String, url: URL) {
    self.name = name
    self.url = url
  }

  convenience init(
    name: String,
    url: URL,
    items: [FeedItem] = [],
    updateInterval: FeedUpdateInterval = .default
  ) {
    self.init(name: name, url: url)
    self.items = items
    self.items = items
    self.updateInterval = updateInterval
  }

  var id: String {
    return self.name
  }

  var unreadItemsCount: Int {
    items
      .filter({ item in item.read != nil }).count
  }
}
@Model class FeedItem: Identifiable {
  var id: String
  var title: String
  var date: Date
  var read: Date?
  var url: URL?

  init(id: String, title: String, date: Date) {
    self.id = id
    self.title = title
    self.date = date
  }

  convenience init(
    id: String, title: String, date: Date, read: Date?, url: URL?
  ) {
    self.init(id: id, title: title, date: date)
    self.read = read
    self.url = url
  }
}