import SwiftUI

// TODO: Expose feeds via environment

@Observable class FeedDataModel {
  var groups: [FeedGroupModel] = []

  init(groups: [FeedGroupModel]) {
    self.groups = groups
  }
}

@Observable class FeedGroupModel: Identifiable {
  var name: String
  var feeds: [FeedModel] = []

  init(name: String) {
    self.name = name
  }

  convenience init(name: String, feeds: [FeedModel]) {
    self.init(name: name)
    self.feeds = feeds
  }

  var id: String {
    return self.name
  }
}

@Observable class FeedModel: Identifiable {
  var id: String
  var url: URL
  var name: String
  var items: [FeedItemModel] = []

  init(id: String, url: URL, name: String) {
    self.id = id
    self.url = url
    self.name = name
  }

  convenience init(id: String, url: URL, name: String, items: [FeedItemModel]) {
    self.init(id: id, url: url, name: name)
    self.items = items
  }

  var unreadItemsCount: Int {
    items
      .filter(\.read).count
  }

}

enum FeedUpdateInterval {
  case `default`
  case hourly
  case daily
  case weekly
  case monthly
}

@Observable class FeedItemModel: Identifiable {
  var id: String
  var title: String
  var date: Date
  var read: Bool = false
  var url: URL?
  var updateInterval: FeedUpdateInterval = .default

  init(id: String, title: String, date: Date) {
    self.id = id
    self.title = title
    self.date = date
  }

  convenience init(
    id: String, title: String, date: Date, read: Bool, url: URL?
  ) {
    self.init(id: id, title: title, date: date)
    self.read = read
    self.url = url
  }
}
