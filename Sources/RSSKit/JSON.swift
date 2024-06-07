import Foundation

func parseJSON(_ data: Data, url: URL) throws -> RSSFeed {
  guard
    let decoded =
      try? JSONSerialization.jsonObject(with: data, options: [])
      as? [String: Any]
  else {
    throw RSSError.invalidRootElementType
  }

  let version = decoded["version"] as? String

  // For now, require JSON feed 1.1 as the only supported JSON type
  switch version {
  case "https://jsonfeed.org/version/1.1":
    // TODO: Validate towards schema?
    return try parseJSONFeedDocument(data, url: url)
  default:
    throw RSSError.unknownContentType
  }
}

private struct JSONFeed: Decodable {
  var version: String
  var title: String
  var items: [JSONFeedItem]

  var home_page_url: URL?
  var feed_url: URL?
  var description: String?
  var user_comment: String?
  var next_url: URL?
  var icon: URL?
  var favicon: URL?
  var author: JSONFeedAuthor?
  var language: String?
  var expired: Bool?
  var hubs: [JSONFeedHub]?
}

private struct JSONFeedAuthor: Decodable {
  var name: String?
  var url: URL?
  var avatar: URL?
}

private struct JSONFeedHub: Decodable {
  var type: String
  var url: URL
}

private struct JSONFeedItem: Decodable {
  var id: String
  var url: URL?
  var external_uri: URL?
  var title: String?
  var content_html: String?
  var content_text: String?
  var summary: String?
  var image: URL?
  var banner_image: URL?
  var date_published: Date?
  var date_modified: Date?
  var author: JSONFeedAuthor?
  var authors: [JSONFeedAuthor]?
  var tags: [String]?
  var language: String?
  var attachments: [JSONFeedAttachment]?
}

private struct JSONFeedAttachment: Decodable {
  var url: URL
  var mime_type: String
  var title: String
  var size_in_bytes: Int
  var duration_in_seconds: Float64
}

func parseJSONFeedDocument(_ data: Data, url: URL) throws -> RSSFeed {
  let decoder = JSONDecoder()
  decoder.dateDecodingStrategy = .iso8601

  let jsonFeed: JSONFeed = try decoder.decode(JSONFeed.self, from: data)

  var entries: [RSSFeedEntry] = []

  for item in jsonFeed.items {
    var entry = RSSFeedEntry(
      id: item.id,
      title: item.title,
      links: [],
      summary: item.summary
    )

    if item.date_modified != nil {
      entry.updated = item.date_modified
    } else {
      entry.updated = item.date_published
    }

    if item.url != nil {
      entry.links.append(item.url!)
    }

    entries.append(entry)
  }

  return RSSFeed(
    url: url, title: jsonFeed.title, updated: nil, entries: entries)
}
