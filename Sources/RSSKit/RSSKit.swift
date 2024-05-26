import Foundation
import HTTPTypes
import HTTPTypesFoundation

enum RSSParseError: Error {
  case invalidRootElementType
}

public func parseRSS(data: Data) throws -> Feed {
  let atomXSDPath = Bundle.module.url(
    forResource: "atom", withExtension: "xsd")!
  let rss2XSDPath = Bundle.module.url(
    forResource: "rss2", withExtension: "xsd")!

  let x = try XMLDocument(
    data: data, options: .nodeLoadExternalEntitiesNever
  )

  let rootElement = x.rootElement()!

  rootElement.addAttribute(
    XMLNode.attribute(
      withName: "xmlns:xsi",
      stringValue: "http://www.w3.org/2001/XMLSchema-instance") as! XMLNode)

  rootElement.addAttribute(
    XMLNode.attribute(
      withName: "xsi:schemaLocation",
      stringValue: "http://www.w3.org/2005/Atom \(atomXSDPath.path())")
      as! XMLNode)

  rootElement.addAttribute(
    XMLNode.attribute(
      withName: "xsi:noNamespaceSchemaLocation",
      stringValue: rss2XSDPath.path())
      as! XMLNode)

  try x.validate()

  if rootElement.uri == "http://www.w3.org/2005/Atom"
    && rootElement.name == "feed"
  {
    return try parseAtomDocument(x)
  } else if rootElement.name == "rss"
    && rootElement.attribute(forName: "version")?.stringValue == "2.0"
  {
    return try parseRSS2Document(x)
  } else {
    throw RSSParseError.invalidRootElementType
  }
}

func parseAtomDocument(_ document: XMLDocument) throws -> Feed {
  var feed = Feed(entries: [])

  if let title = try document.nodes(forXPath: "/feed/title").first {
    feed.title = title.stringValue!
  }

  if let lastBuildDate = try document.nodes(
    forXPath: "/feed/updated"
  )
  .first {
    feed.updated = Date(fromRFC3339: lastBuildDate.stringValue!)
  }

  for item in try document.nodes(forXPath: "/feed/entry") {
    var entry = FeedEntry(links: [])

    if let title = try item.nodes(forXPath: "./title").first {
      entry.title = title.stringValue!
    }

    let links = try item.nodes(forXPath: "./link/@href")
    entry.links = links.map {
      URL(string: $0.stringValue!)!
    }

    if let summary = try item.nodes(
      forXPath: "./summary"
    ).first {
      entry.summary = summary
        .stringValue!
    }

    if let updated = try item.nodes(forXPath: "./updated").first {
      entry.updated = Date(fromRFC3339: updated.stringValue!)
    }

    if let id = try item.nodes(forXPath: "./id").first {
      entry.id = id.stringValue!
    }

    if let content = try item.nodes(forXPath: "./content").first {
      entry.contentType = try content.nodes(forXPath: "./@type")
        .first?.stringValue!
      entry.content = content.stringValue
    }

    feed.entries.append(entry)
  }

  return feed
}

func parseRSS2Document(_ document: XMLDocument) throws -> Feed {
  var feed = Feed()

  if let title = try document.nodes(forXPath: "/rss/channel/title").first {
    feed.title = title.stringValue!
  }

  if let lastBuildDate = try document.nodes(
    forXPath: "/rss/channel/lastBuildDate"
  )
  .first {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US")
    // Fri, 21 Jul 2023 09:04 EDT
    dateFormatter.dateFormat = "E, d LLL y H:m z"
    let date = dateFormatter.date(from: lastBuildDate.stringValue!)!
    feed.updated = date
  }

  for item in try document.nodes(forXPath: "/rss/channel/item") {
    var entry = FeedEntry(links: [])

    if let title = try item.nodes(forXPath: "/rss/channel/item/title").first {
      entry.title = title.stringValue!
    }

    if let link = try item.nodes(forXPath: "/rss/channel/item/link").first {
      entry.links = [URL(string: link.stringValue!)!]
    }

    if let description = try item.nodes(
      forXPath: "/rss/channel/item/description"
    ).first {
      entry.summary = description.stringValue!
    }

    if let pubDate = try item.nodes(forXPath: "/rss/channel/item/pubDate").first
    {
      let dateFormatter = DateFormatter()
      dateFormatter.locale = Locale(identifier: "en_US_POSIX")
      dateFormatter.dateFormat = "E, d LLL y H:m z"
      let date = dateFormatter.date(from: pubDate.stringValue!)!
      feed.updated = date
    }

    if let guid = try item.nodes(forXPath: "/rss/channel/item/guid").first {
      entry.id = guid.stringValue!
    }

    feed.entries.append(entry)
  }

  return feed
}

// SEE: https://www.rfc-editor.org/rfc/rfc5005.html
public struct RSSFeed {
  var url: URL

  public init(url: URL) {
    self.url = url
  }

  public func fetch() async throws {
    var request = HTTPRequest(method: .get, url: self.url)
    request.headerFields[.accept] = "application/atom+xml"
    request.headerFields[.userAgent] = "RSSBar/1.0"

    let (responseBody, _) = try await URLSession.shared.download(
      for: request)

    // let x = parseRSS(contentsOf: responseBody)!
  }

}

public struct Feed {
  var title: String?
  var updated: Date?
  var entries: [FeedEntry]

  init() {
    self.entries = []
  }
}

public struct FeedEntry {
  var title: String?
  var links: [URL]
  var summary: String?
  var id: String?
  var updated: Date?
}
