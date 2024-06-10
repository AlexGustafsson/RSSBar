import Foundation
import HTTPTypes
import HTTPTypesFoundation

enum RSSError: Error {
  case invalidRootElementType
  case invalidContentType
  case unknownContentType
}

public struct RSSFeed: Equatable, Identifiable {
  public var url: URL
  public var title: String?
  public var updated: Date?
  public var entries: [RSSFeedEntry]

  public init(url: URL, title: String?, updated: Date?, entries: [RSSFeedEntry])
  {
    self.url = url
    self.title = title
    self.updated = updated
    self.entries = entries
  }

  public init(url: URL, entries: [RSSFeedEntry]) {
    self.url = url
    self.entries = entries
  }

  public init(url: URL, data: Data, contentType: String) throws {
    switch contentType {
    case "text/xml", "application/xml", "application/rss+xml",
      "application/atom+xml":
      self = try parseXML(data, url: url)
    case "application/feed+json": self = try parseJSON(data, url: url)
    default: throw RSSError.invalidContentType
    }
  }

  public init(contentsOf url: URL) async throws {
    var request = HTTPRequest(method: .get, url: url)
    request.headerFields[.accept] =
      "application/atom+xml,application/rss+xml,application/feed+json,text/xml"
    request.headerFields[.userAgent] = "RSSBar/1.0"

    let (responseBody, response) = try await URLSession.shared.download(
      for: request)

    var contentType = response.headerFields[.contentType]
    if let actualContentType = contentType?.cut(at: ";")?.0 {
      contentType = String(actualContentType)
    }

    // If the server didn't respond with a content type, try to identify it from
    // the file extension
    if contentType == nil {
      // TODO: Warn
      switch url.pathExtension {
      case "rss": contentType = "application/rss+xml"
      case "atom": contentType = "application/atom+xml"
      case "json": contentType = "application/json"
      case "xml": contentType = "text/xml"
      default: throw RSSError.unknownContentType
      }
    }

    try self.init(
      url: url, data: Data(contentsOf: responseBody), contentType: contentType!)
  }

  public var id: String { return self.url.absoluteString }
}

public struct RSSFeedEntry: Equatable, Identifiable {
  public var id: String
  public var title: String?
  public var links: [URL]
  public var summary: String?
  public var updated: Date?
}

/// Build a deterministic UUID. The UUID is a UUIDv8 based on the hash of the
/// namespace and the first non-nil value. If no value exists, the fallback is
/// used.
func generateId(namespace: String, fallback: String, _ values: String?...)
  -> UUID
{
  let values = values.filter({ $0 != nil }) as! [String]
  return UUID.v8(withHash: namespace + "\n" + (values.first ?? fallback))
}
