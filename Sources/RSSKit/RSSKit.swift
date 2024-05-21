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

    let x = parseRSS(contentsOf: responseBody)

    print("Foo: \(x!)")
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

public func parseRSS(contentsOf: URL) -> XMLNode? {
  let parser = XMLParser(contentsOf: contentsOf)!
  let parserDelegate = XMLParserDelegateX()
  parser.delegate = parserDelegate

  parser.parse()

  return parserDelegate.root
}

public func parseRSS(data: Data) -> XMLNode? {
  let parser = XMLParser(data: data)
  let parserDelegate = XMLParserDelegateX()
  parser.delegate = parserDelegate

  parser.parse()

  return parserDelegate.root
}

public class XMLNode {
  var tag: String
  var attributes: [String: String]
  var text: String?
  var children: [XMLNode]
  var parent: XMLNode?

  init(tag: String, attributes: [String: String]) {
    self.tag = tag
    self.attributes = attributes
    self.children = []
  }

}

// TODO: Copy the struct print format
extension XMLNode: CustomStringConvertible {
  public var description: String {
    return "<\(self.tag) [\(self.attributes)]>\(self.children)</\(self.tag)>"
  }
}

// TODO: Copy the struct print format
extension XMLNode: CustomDebugStringConvertible {
  public var debugDescription: String {
    return "<\(self.tag) [\(self.attributes)]>\(self.children)</\(self.tag)>"
  }
}

// TODO: Yield for each entry to save memory? Now the entire tree is built and
// returned, which is unnecessary.
class XMLParserDelegateX: NSObject, XMLParserDelegate {
  var root: XMLNode?
  var current: XMLNode?

  func parser(
    _ parser: XMLParser,
    didStartElement elementName: String,
    namespaceURI: String?,
    qualifiedName: String?,
    attributes: [String: String] = [:]
  ) {
    print(elementName)
    let node = XMLNode(tag: elementName, attributes: attributes)
    if self.current == nil {
      print("is root")
      self.root = node
    } else {
      print("has parent \(self.current!.tag)")
      self.current!.children.append(node)
      node.parent = self.current
    }
    self.current = node
  }

  func parser(
    _ parser: XMLParser,
    foundCharacters text: String
  ) {
    if self.current?.text == nil {
      self.current!.text = text
    } else {
      self.current!.text! += text
    }
  }

  func parser(
    _ parser: XMLParser,
    didEndElement elementName: String,
    namespaceURI: String?,
    qualifiedName qName: String?
  ) {
    self.current = self.current?.parent
  }
}
