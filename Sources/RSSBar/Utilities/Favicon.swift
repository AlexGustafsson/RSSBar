import Foundation
import HTTPTypes
import HTTPTypesFoundation

enum FaviconError: Error {
  case invalidURL
  case notFound
  case badStatus
}

struct Favicon {
  public static func identifyIcons(from url: String) async throws -> [URL] {
    var urls: [URL] = []

    guard let origin = URLComponents(string: url) else {
      throw FaviconError.invalidURL
    }

    // Always include the well-known favicon.ico file
    var faviconLocation = URLComponents()
    faviconLocation.scheme = origin.scheme
    faviconLocation.host = origin.host
    faviconLocation.port = origin.port
    faviconLocation.path = "/favicon.ico"
    urls.append(faviconLocation.url!)

    // Fetch the index document to see if it has icons listed in its metadata
    var documentLocation = URLComponents()
    documentLocation.scheme = origin.scheme
    documentLocation.host = origin.host
    documentLocation.port = origin.port
    documentLocation.path = "/"

    var request = HTTPRequest(method: .get, url: documentLocation.url!)
    request.headerFields[.accept] = "text/html"
    request.headerFields[.userAgent] = "RSSBar/1.0"

    let (responseBody, response) = try await URLSession.shared.download(
      for: request)

    if response.status.code != 200 {
      return urls
    }

    guard
      let document = try? XMLDocument(
        contentsOf: responseBody,
        options: [
          .nodeLoadExternalEntitiesNever, .documentTidyHTML,
        ]
      )
    else {
      // Failed to parse document
      // TODO: Log
      return urls
    }

    for icon in try document.nodes(
      forXPath: "/html/head/link[@rel=(\"icon\", \"alternate icon\")]/@href")
    {
      if let url = URL(string: icon.stringValue!) {
        urls.append(url)
      }
    }

    return urls
  }

  public static func fetch(contentsOf url: URL) async throws -> URL? {
    var request = HTTPRequest(method: .get, url: url)
    request.headerFields[.accept] = "image/svg+xml, image/png, image/x-icon"
    request.headerFields[.userAgent] = "RSSBar/1.0"

    let (responseBody, response) = try await URLSession.shared.download(
      for: request)

    if response.status.code == 400 {
      return nil
    } else if response.status.code != 200 {
      throw FaviconError.badStatus
    }

    return responseBody
  }
}
