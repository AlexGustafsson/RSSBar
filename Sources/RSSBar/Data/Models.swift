import Foundation
import SwiftData

@Model final class FeedGroup: Codable {
  var name: String
  @Relationship(deleteRule: .cascade, inverse: \Feed.group) var feeds: [Feed] =
    []
  var order: Int = 0

  enum CodingKeys: CodingKey {
    case name
    case feeds
    case order
  }

  init(name: String) { self.name = name }

  convenience init(name: String, feeds: [Feed] = []) {
    self.init(name: name)
    self.feeds = feeds
  }

  public required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.name = try container.decode(String.self, forKey: .name)
    self.feeds = try container.decode([Feed].self, forKey: .feeds)
    self.order = try container.decode(Int.self, forKey: .order)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(name, forKey: .name)
    try container.encode(feeds, forKey: .feeds)
    try container.encode(order, forKey: .order)
  }
}

@Model final class Feed: Codable {
  var name: String
  var url: URL

  @Relationship(deleteRule: .cascade, inverse: \FeedItem.feed) var items:
    [FeedItem] = []
  var lastUpdated: Date?
  var order: Int = 0

  var group: FeedGroup?

  enum CodingKeys: CodingKey {
    case name
    case url
    case items
    case lastUpdated
    case order
  }

  init(name: String, url: URL) {
    self.name = name
    self.url = url
  }

  convenience init(
    name: String, url: URL, items: [FeedItem] = []
  ) {
    self.init(name: name, url: url)
    self.items = items
    self.items = items
  }

  var unreadItemsCount: Int { items.filter({ item in item.read == nil }).count }

  public required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.name = try container.decode(String.self, forKey: .name)
    self.url = try container.decode(URL.self, forKey: .url)
    self.items = try container.decode([FeedItem].self, forKey: .items)
    self.lastUpdated = try container.decode(Date?.self, forKey: .lastUpdated)
    self.order = try container.decode(Int.self, forKey: .order)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(name, forKey: .name)
    try container.encode(url, forKey: .url)
    try container.encode(items, forKey: .items)
    try container.encode(lastUpdated, forKey: .lastUpdated)
    try container.encode(order, forKey: .order)
  }
}
@Model final class FeedItem: Codable {
  @Attribute(.unique) var id: String
  var title: String
  var date: Date?
  var read: Date?
  var url: URL?

  var feed: Feed?

  enum CodingKeys: CodingKey {
    case id
    case title
    case date
    case read
    case url
  }

  init(id: String, title: String) {
    self.id = id
    self.title = title
    self.date = date
  }

  convenience init(
    id: String, title: String, date: Date?, read: Date?, url: URL?
  ) {
    self.init(id: id, title: title)
    self.date = date
    self.read = read
    self.url = url
  }

  public required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decode(String.self, forKey: .id)
    self.title = try container.decode(String.self, forKey: .title)
    self.date = try container.decode(Date?.self, forKey: .date)
    self.read = try container.decode(Date?.self, forKey: .read)
    self.url = try container.decode(URL?.self, forKey: .url)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(title, forKey: .title)
    try container.encode(date, forKey: .date)
    try container.encode(read, forKey: .read)
    try container.encode(url, forKey: .url)
  }
}
