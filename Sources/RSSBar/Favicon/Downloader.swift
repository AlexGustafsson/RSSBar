import Foundation
import HTTPTypes
import HTTPTypesFoundation

enum FaviconDownloadError: Error {
  case invalidURL
  case notFound
  case badStatus
}

private struct FaviconURL {
  var url: URL
  var sizes: [(Int, Int)]
  var type: String?
}

struct FaviconDownloader {
  public static func identifyIcons(from url: String) async throws -> [URL] {
    var urls: [FaviconURL] = []

    guard let origin = URLComponents(string: url) else {
      throw FaviconDownloadError.invalidURL
    }

    // Always include the well-known favicon.ico file
    var faviconLocation = URLComponents()
    faviconLocation.scheme = origin.scheme
    faviconLocation.host = origin.host
    faviconLocation.port = origin.port
    faviconLocation.path = "/favicon.ico"
    urls.append(
      FaviconURL(url: faviconLocation.url!, sizes: [], type: "image/x-icon"))

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

    if response.status.code == 200 {
      if let document = try? XMLDocument(
        contentsOf: responseBody,
        options: [
          .nodeLoadExternalEntitiesNever, .documentTidyHTML,
        ]
      ) {
        for icon in try document.nodes(
          forXPath: "/html/head/link[@rel=(\"icon\", \"alternate icon\")]"
        ) {
          // For now, only support pngs (there are image source sets, icons sets
          // and more that we don't want to handle right now).
          let typeNodes = try? icon.nodes(forXPath: "./@type")
          let type = typeNodes?.first?.stringValue
          if type != "image/png" {
            continue
          }
          let sizesNode = try? icon.nodes(forXPath: "./@sizes")
          let sizes = (sizesNode?.first?.stringValue ?? "").split(
            separator: " "
          ).map({ x in
            let scalars = x.split(separator: "x").map({ Int($0)! })
            return (scalars[0], scalars[1])
          })

          let hrefNodes = try? icon.nodes(forXPath: "./@href")
          if let href = hrefNodes?.first {
            if let url = URLComponents(string: href.stringValue!) {
              urls.append(
                FaviconURL(
                  url: url.url(relativeTo: documentLocation.url!)!,
                  sizes: sizes,
                  type: type
                ))
            }
          }
        }
      }
    }

    // Sort the URLs, trying to prioritize the highest resolution ones
    urls.sort(by: { a, b in
      if a.type == "image/png" && b.type != "image/png" {
        return true
      }

      if a.sizes.count == 1 && b.sizes.count == 1 {
        return a.sizes[0].0 > b.sizes[0].0

      }

      return false
    })

    return urls.map { $0.url }
  }

  public static func download(contentsOf url: URL) async throws -> URL? {
    var request = HTTPRequest(method: .get, url: url)
    request.headerFields[.accept] = "image/svg+xml, image/png, image/x-icon"
    request.headerFields[.userAgent] = "RSSBar/1.0"

    let (responseBody, response) = try await URLSession.shared.download(
      for: request)

    if response.status.code == 404 {
      return nil
    } else if response.status.code != 200 {
      throw FaviconDownloadError.badStatus
    }

    return responseBody
  }
}
