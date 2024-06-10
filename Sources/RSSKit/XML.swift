import Foundation

func parseXML(_ data: Data, url: URL) throws -> RSSFeed {
  let atomXSDPath = Bundle.module.url(
    forResource: "atom", withExtension: "xsd")!
  let rss2XSDPath = Bundle.module.url(
    forResource: "rss2", withExtension: "xsd")!

  let document = try XMLDocument(
    data: data, options: .nodeLoadExternalEntitiesNever)

  guard let rootElement = document.rootElement() else {
    throw RSSError.invalidRootElementType
  }

  // Declare the XMLSchema instance namespace
  rootElement.addAttribute(
    XMLNode.attribute(
      withName: "xmlns:xsi",
      stringValue: "http://www.w3.org/2001/XMLSchema-instance") as! XMLNode)

  // Add the schema location of available XSDs
  // NOTE: Here's a good place to add additional XSDs (space-separated values
  // in stringValue)
  rootElement.addAttribute(
    XMLNode.attribute(
      withName: "xsi:schemaLocation",
      stringValue: "http://www.w3.org/2005/Atom \(atomXSDPath.path())")
      as! XMLNode)

  // The RSS format uses no namespace, so declare the XSD as a schema without
  // a given namespace
  rootElement.addAttribute(
    XMLNode.attribute(
      withName: "xsi:noNamespaceSchemaLocation", stringValue: rss2XSDPath.path()
    ) as! XMLNode)

  try document.validate()

  if rootElement.uri == "http://www.w3.org/2005/Atom"
    && rootElement.name == "feed"
  {
    return try parseAtomDocument(document, url: url)
  } else if rootElement.name == "rss"
    && rootElement.attribute(forName: "version")?.stringValue == "2.0"
  {
    return try parseRSS2Document(document, url: url)
  } else {
    throw RSSError.invalidRootElementType
  }
}

func parseAtomDocument(_ document: XMLDocument, url: URL) throws -> RSSFeed {
  let title = try document.nodes(forXPath: "/feed/title").first?.stringValue
  let updated = try document.nodes(forXPath: "/feed/updated").first?.stringValue

  var feed = RSSFeed(
    url: url, title: title,
    updated: updated == nil ? nil : Date(fromRFC3339: updated!), entries: [])

  for (i, item) in try document.nodes(forXPath: "/feed/entry").enumerated() {
    let title = try item.nodes(forXPath: "./title").first?.stringValue
    let links = try item.nodes(forXPath: "./link/@href")
      .map {
        URL(string: $0.stringValue!)!
      }
    let summary = try item.nodes(forXPath: "./summary").first?.stringValue
    let updated = try item.nodes(forXPath: "./updated").first?.stringValue

    // Prioritize existing ids, then likely unique values, fall back to the
    // entry's index in the feed
    let id = generateId(
      namespace: url.absoluteString, fallback: String(i),
      try? item.nodes(forXPath: "./id").first?.stringValue, title,
      links.first?.absoluteString, updated)

    let entry = RSSFeedEntry(
      id: id, title: title, links: links, summary: summary,
      updated: updated == nil ? nil : Date(fromRFC3339: updated!))

    feed.entries.append(entry)
  }

  return feed
}

func parseRSS2Document(_ document: XMLDocument, url: URL) throws -> RSSFeed {

  let title = try document.nodes(forXPath: "/rss/channel/title").first?
    .stringValue
  let pubDate = try document.nodes(forXPath: "/rss/channel/pubDate").first?
    .stringValue
  let lastBuildDate = try document.nodes(forXPath: "/rss/channel/lastBuildDate")
    .first?
    .stringValue

  let updated = lastBuildDate ?? pubDate

  var feed = RSSFeed(
    url: url, title: title,
    updated: updated == nil ? nil : Date(fromRFC2822: updated!), entries: [])

  for (i, item) in try document.nodes(forXPath: "/rss/channel/item")
    .enumerated()
  {
    let guid = try item.nodes(forXPath: "./guid").first?.stringValue
    let title = try item.nodes(forXPath: "./title").first?.stringValue
    let link = try item.nodes(forXPath: "./link").first?.stringValue
    let description = try item.nodes(forXPath: "./description").first?
      .stringValue
    let pubDate = try item.nodes(forXPath: "./pubDate").first?.stringValue

    // Prioritize existing ids, then likely unique values, fall back to the
    // entry's index in the feed
    let id = generateId(
      namespace: url.absoluteString, fallback: String(i), guid, link, title,
      pubDate, description)

    let entry = RSSFeedEntry(
      id: id, title: title, links: link == nil ? [] : [URL(string: link!)!],
      summary: description,
      updated: pubDate == nil ? nil : Date(fromRFC2822: pubDate!))

    feed.entries.append(entry)
  }

  return feed
}
