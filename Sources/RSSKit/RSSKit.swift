import Foundation
import HTTPTypes
import HTTPTypesFoundation

public class RSSDocument: XMLDocument {
  public override func setRootElement(_ root: XMLElement) {
    print(root)
    super.setRootElement(root)
  }
}

public func parseRSS(data: Data) throws {
  let xsd = Bundle.module.url(
    forResource: "atom", withExtension: "xsd")!

  let x = try RSSDocument(
    data: data, options: .nodeLoadExternalEntitiesNever  // TODO: Never
  )

  x.rootElement()!.addAttribute(
    XMLNode.attribute(
      withName: "xmlns:xsi",
      stringValue: "http://www.w3.org/2001/XMLSchema-instance") as! XMLNode)

  x.rootElement()!.addAttribute(
    XMLNode.attribute(
      withName: "xsi:schemaLocation",
      stringValue: "http://www.w3.org/2005/Atom \(xsd.path())")
      as! XMLNode)

  try x.validate()
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

struct Feed {
  var title: String?
  var subtitle: String?
  var links: [FeedLink]
  var updated: Date?
  var author: FeedAuthor?
  var id: String?
  var entries: [FeedEntry]

  init() {
    self.links = []
    self.entries = []
  }
}

struct FeedLink {
  var url: URL?
  var rel: String?
}

struct FeedAuthor {
  var name: String?
}

struct FeedEntry {
  var title: String?
  var links: [FeedLink]
  var id: String?
  var updated: Date?
  var summary: String?

  init() {
    self.links = []
  }
}

// <?xml version="1.0" encoding="utf-8"?>
//  <feed xmlns="http://www.w3.org/2005/Atom"
//   xmlns:fh="http://purl.org/syndication/history/1.0">
//   <title>NetMovies Queue</title>
//   <subtitle>The DVDs you'll receive next.</subtitle>
//   <link href="http://example.org/"/>
//   <fh:complete/>
//   <link rel="self"
//    href="http://netmovies.example.org/jdoe/queue/index.atom"/>
//   <updated>2003-12-13T18:30:02Z</updated>
//   <author>
//     <name>John Doe</name>
//   </author>
//   <id>urn:uuid:60a76c80-d399-11d9-b93C-0003939e0af6</id>
//   <entry>
//     <title>Casablanca</title>
//     <link href="http://netmovies.example.org/movies/Casablanca"/>
//     <id>urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a</id>
//     <updated>2003-12-13T18:30:02Z</updated>
//     <summary>Here's looking at you, kid...</summary>
//   </entry>
//  </feed>
