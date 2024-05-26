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
  var feed = Feed(entries: [])

  if let title = try document.nodes(forXPath: "/rss/channel/title").first {
    feed.title = title.stringValue!
  }

  // TODO: Use last build date, fall back to pub date
  if let lastBuildDate = try document.nodes(
    forXPath: "/rss/channel/lastBuildDate"
  )
  .first {
    feed.updated = Date(fromRFC2822: lastBuildDate.stringValue!)
  }

  for item in try document.nodes(forXPath: "/rss/channel/item") {
    var entry = FeedEntry(links: [])

    if let title = try item.nodes(forXPath: "./title").first {
      entry.title = title.stringValue!
    }

    if let link = try item.nodes(forXPath: "./link").first {
      entry.links = [URL(string: link.stringValue!)!]
    }

    if let description = try item.nodes(
      forXPath: "./description"
    ).first {
      entry.summary = description.stringValue!
    }

    // TODO: Use last build date, fall back to pub date
    if let pubDate = try item.nodes(forXPath: "./pubDate").first {
      entry.updated = Date(fromRFC2822: pubDate.stringValue!)
    }

    if let guid = try item.nodes(forXPath: "./guid").first {
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

public struct Feed: Equatable {
  public var title: String?
  public var updated: Date?
  public var entries: [FeedEntry]
}

public struct FeedEntry: Equatable {
  public var title: String?
  public var links: [URL]
  public var summary: String?
  public var id: String?
  public var updated: Date?
  public var contentType: String?
  public var content: String?
}
