import Foundation
import HTTPTypes
import HTTPTypesFoundation

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

    let parser = XMLParser(contentsOf: responseBody)!
    let feedDelegate = FeedDelegate()
    parser.delegate = feedDelegate
    parser.parse()

    print("Foo: \(feedDelegate.feed)")
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

enum FeedParserState {
  case root
  case feed
  case author
  case entry
}

class FeedDelegate: NSObject, XMLParserDelegate {
  var feed: Feed = Feed()
  var entry: FeedEntry?
  var state: FeedParserState = .root

  func parserDidStartDocument(_ parser: XMLParser) {
    print("Start of the document")
    print("Line number: \(parser.lineNumber)")
  }

  func parserDidEndDocument(_ parser: XMLParser) {
    print("End of the document")
    print("Line number: \(parser.lineNumber)")
  }

  func parser(
    _ parser: XMLParser,
    didStartElement elementName: String,
    namespaceURI: String?,
    qualifiedName: String?,
    attributes: [String: String] = [:]
  ) {
    let text = ""
    print("Got element \(elementName)")
    switch self.state {
    case .root:
      switch elementName {
      case "feed":
        self.state = .feed
      default:
        return
      }
    case .feed:
      switch elementName {
      case "title":
        self.feed.title = text.trimmingCharacters(in: .whitespacesAndNewlines)
      case "subtitle":
        self.feed.subtitle = text.trimmingCharacters(
          in: .whitespacesAndNewlines)
      case "link":
        let url = URL(string: attributes["href"]!)!
        let rel = attributes["rel"]
        self.feed.links.append(FeedLink(url: url, rel: rel))
      case "author":
        self.feed.author = FeedAuthor()
        self.state = .author
      case "id":
        self.feed.id = text.trimmingCharacters(in: .whitespacesAndNewlines)
      case "updated":
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-ddTHH:mm:ssZ"
        self.feed.updated = formatter.date(
          from: text.trimmingCharacters(in: .whitespacesAndNewlines)
        )
      case "entry":
        self.entry = FeedEntry()
        self.state = .entry
      default:
        return
      }
    case .author:
      switch elementName {
      case "name":
        self.feed.author?.name = text.trimmingCharacters(
          in: .whitespacesAndNewlines)
      default:
        return
      }
    case .entry:
      switch elementName {
      case "title":
        self.entry?.title = text.trimmingCharacters(in: .whitespacesAndNewlines)
      case "link":
        let url = URL(string: attributes["href"]!)!
        let rel = attributes["rel"]
        self.entry?.links.append(FeedLink(url: url, rel: rel))
      case "id":
        self.entry?.id = text.trimmingCharacters(in: .whitespacesAndNewlines)
      case "updated":
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-ddTHH:mm:ssZ"
        self.entry?.updated = formatter.date(
          from: text.trimmingCharacters(in: .whitespacesAndNewlines)
        )
      case "summary":
        self.entry?.summary = text.trimmingCharacters(
          in: .whitespacesAndNewlines)
      default:
        return
      }
    }
  }

  func parser(
    _ parser: XMLParser,
    foundCharacters text: String
  ) {
    print("Got text \(text)")
  }

  func parser(
    _ parser: XMLParser,
    didEndElement elementName: String,
    namespaceURI: String?,
    qualifiedName qName: String?
  ) {
    if self.state == .feed && elementName == "feed" {
      self.state = .root
    } else if self.state == .author && elementName == "author" {
      self.state = .feed
    } else if self.state == .entry && elementName == "entry" {
      self.state = .feed
      self.feed.entries.append(self.entry!)
      self.entry = nil
    }
  }

}
