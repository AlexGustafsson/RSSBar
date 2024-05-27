import Foundation
import HTTPTypes
import HTTPTypesFoundation

enum FaviconDownloadError: Error {
  case invalidURL
  case notFound
  case badStatus
}

struct FaviconDownloader {
  public static func identifyIcons(from url: String) async throws -> [URL] {
    print("Identifying")
    var urls: [URL] = []

    guard let origin = URLComponents(string: url) else {
      throw FaviconDownloadError.invalidURL
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
      if let url = URLComponents(string: icon.stringValue!) {
        urls.append(url.url(relativeTo: documentLocation.url!)!)
      }
    }

    return urls
  }

  public static func download(contentsOf url: URL) async throws -> URL? {
    print("Downloading")
    var request = HTTPRequest(method: .get, url: url)
    request.headerFields[.accept] = "image/svg+xml, image/png, image/x-icon"
    request.headerFields[.userAgent] = "RSSBar/1.0"

    let (responseBody, response) = try await URLSession.shared.download(
      for: request)

    if response.status.code == 400 {
      return nil
    } else if response.status.code != 200 {
      throw FaviconDownloadError.badStatus
    }

    return responseBody
  }
}
