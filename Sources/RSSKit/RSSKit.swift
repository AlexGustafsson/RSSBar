import Foundation
import HTTPTypes
import HTTPTypesFoundation

enum RSSError: Error {
  case invalidRootElementType
  case invalidContentType
  case unknownContentType
}

public struct RSSFeed: Equatable {
  public var title: String?
  public var updated: Date?
  public var entries: [RSSFeedEntry]

  public init(title: String?, updated: Date?, entries: [RSSFeedEntry]) {
    self.title = title
    self.updated = updated
    self.entries = entries
  }

  public init(entries: [RSSFeedEntry]) {
    self.entries = entries
  }

  public init(data: Data, contentType: String) throws {
    switch contentType {
    case "text/xml", "application/xml", "application/rss+xml",
      "application/atom+xml":
      self = try parseXML(data)
    case "application/feed+json":
      self = try parseJSON(data)
    default:
      throw RSSError.invalidContentType
    }
  }

  public init(download url: URL) async throws {
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
      case "rss":
        contentType = "application/rss+xml"
      case "atom":
        contentType = "application/atom+xml"
      case "json":
        contentType = "application/json"
      case "xml":
        contentType = "text/xml"
      default:
        throw RSSError.unknownContentType
      }
    }

    try self.init(
      data: Data(contentsOf: responseBody), contentType: contentType!)
  }
}

public struct RSSFeedEntry: Equatable {
  public var title: String?
  public var links: [URL]
  public var summary: String?
  public var id: String?
  public var updated: Date?
  public var contentType: String?
  public var content: String?
}
