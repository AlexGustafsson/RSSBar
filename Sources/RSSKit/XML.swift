import Foundation

func parseXML(_ data: Data, url: URL) throws -> RSSFeed {
  let atomXSDPath = Bundle.module.url(
    forResource: "atom", withExtension: "xsd")!
  let rss2XSDPath = Bundle.module.url(
    forResource: "rss2", withExtension: "xsd")!
  let mrssXSDPath = Bundle.module.url(
    forResource: "mrss", withExtension: "xsd")!

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
      stringValue:
        "http://www.w3.org/2005/Atom \(atomXSDPath.path())"
    )
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
    return try parseAtomDocument(x, url: url)
  } else if rootElement.name == "rss"
    && rootElement.attribute(forName: "version")?.stringValue == "2.0"
  {
    return try parseRSS2Document(x, url: url)
  } else {
    throw RSSError.invalidRootElementType
  }
}

func parseAtomDocument(_ document: XMLDocument, url: URL) throws -> RSSFeed {
  var feed = RSSFeed(url: url, entries: [])

  if let title = try document.nodes(forXPath: "/feed/title").first {
    feed.title = title.stringValue!
  }

  if let lastBuildDate = try document.nodes(
    forXPath: "/feed/updated"
  )
  .first {
    feed.updated = Date(fromRFC3339: lastBuildDate.stringValue!)
  }

  for (i, item) in try document.nodes(forXPath: "/feed/entry").enumerated() {
    let title = try item.nodes(forXPath: "./title").first?.stringValue
    let links = try item.nodes(forXPath: "./link/@href").map {
      URL(string: $0.stringValue!)!
    }
    let summary = try item.nodes(forXPath: "./summary").first?.stringValue
    let updated = try item.nodes(forXPath: "./updated").first?.stringValue

    let id =
      UUID.v8(
        withHash:
          "\(url)\((try? item.nodes(forXPath: "./id").first?.stringValue) ?? title ?? links.first?.absoluteString ?? updated ?? String(i))"
      )

    var entry = RSSFeedEntry(id: id, links: links)
    entry.title = title
    entry.summary = summary
    entry.updated = updated == nil ? nil : Date(fromRFC3339: updated!)

    feed.entries.append(entry)
  }

  return feed
}

func parseRSS2Document(_ document: XMLDocument, url: URL) throws -> RSSFeed {
  var feed = RSSFeed(url: url, entries: [])

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

  for (i, item) in try document.nodes(forXPath: "/rss/channel/item")
    .enumerated()
  {
    let guid = try item.nodes(forXPath: "./guid").first?.stringValue
    let title = try item.nodes(forXPath: "./title").first?.stringValue
    let link = try item.nodes(forXPath: "./link").first?.stringValue
    let description = try item.nodes(forXPath: "./description").first?
      .stringValue
    let pubDate = try item.nodes(forXPath: "./pubDate").first?.stringValue

    let id = UUID.v8(
      withHash:
        "\(url)\(guid ?? link ?? title ?? pubDate ?? description ?? String(i))")
    var entry = RSSFeedEntry(id: id, links: [])
    entry.title = title
    entry.links = link == nil ? [] : [URL(string: link!)!]
    entry.summary = description
    entry.updated = pubDate == nil ? nil : Date(fromRFC2822: pubDate!)

    feed.entries.append(entry)
  }

  return feed
}
