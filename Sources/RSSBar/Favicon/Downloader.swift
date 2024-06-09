import Foundation
import HTTPTypes
import HTTPTypesFoundation
import os

enum FaviconDownloadError: Error {
  case invalidURL
  case notFound
  case badStatus
  case unknownContentType
}

private struct FaviconURL {
  var url: URL
  var sizes: [(Int, Int)]
  var type: String?
}

protocol FaviconDownloader {
  func identifyIcons(from url: URL) async throws -> [URL]
  func download(contentsOf url: URL) async throws -> URL?
  func downloadPreferred(from url: URL) async throws -> URL?
}

private let logger = Logger(
  subsystem: Bundle.main.bundleIdentifier!, category: "UI/Favicon")

struct BasicFaviconDownloader: FaviconDownloader {
  public func identifyIcons(from url: URL) async throws -> [URL] {
    var urls: [FaviconURL] = []

    guard let origin = URLComponents(url: url, resolvingAgainstBaseURL: false)
    else {
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

    // Remove metadata and filter bogus URLs
    return urls.map { $0.url }.filter({
      ($0.scheme == "http" || $0.scheme == "https") && $0.host() != nil
    })
  }

  public func download(contentsOf url: URL) async throws -> URL? {
    var request = HTTPRequest(method: .get, url: url)

    let supportedContentTypes = [
      "image/svg+xml", "image/png", "image/x-icon", "image/vnd.microsoft.icon",
    ]

    request.headerFields[.accept] = supportedContentTypes.joined(
      separator: ", ")
    request.headerFields[.userAgent] = "RSSBar/1.0"

    let (responseBody, response) = try await URLSession.shared.download(
      for: request)

    if response.status.code == 404 {
      return nil
    } else if response.status.code != 200 {
      throw FaviconDownloadError.badStatus
    }

    var contentType = response.headerFields[.contentType]
    if let actualContentType = contentType?.cut(at: ";")?.0 {
      contentType = String(actualContentType)
    }

    // If the server didn't respond with a content type, try to identify it from
    // the file extension
    if contentType == nil {
      // TODO: Warn
      switch url.pathExtension {
      case "svg":
        contentType = "image/svg+xml"
      case "png":
        contentType = "image/png"
      case "ico":
        contentType = "image/x-icon"
      default:
        throw FaviconDownloadError.unknownContentType
      }
    }

    // Handle default / error page handling in some pages
    if contentType == "text/xml" || contentType == "text/html" {
      return nil
    }

    if !supportedContentTypes.contains(contentType!) {
      logger.warning(
        "Unsupported content type for image \(url, privacy: .public)")
      throw FaviconDownloadError.unknownContentType
    }

    return responseBody
  }

  func downloadPreferred(from url: URL) async throws -> URL? {
    let urls = try await self.identifyIcons(from: url)

    guard let url = urls.first else {
      logger.debug("Didn't find any favicons for url: \(url, privacy: .public)")
      return nil
    }

    return try await self.download(contentsOf: url)
  }
}

// TODO: Pass cache
struct CachedFaviconDownloader: FaviconDownloader {
  private let underlyingDownloader: any FaviconDownloader
  init(underlyingDownloader: any FaviconDownloader) {
    self.underlyingDownloader = underlyingDownloader
  }

  func identifyIcons(from url: URL) async throws -> [URL] {
    return try await self.underlyingDownloader.identifyIcons(from: url)
  }

  func download(contentsOf url: URL) async throws -> URL? {
    guard let origin = url.host() else {
      throw FaviconDownloadError.invalidURL
    }

    if let data = DiskCache.shared.urlIfExists(forKey: origin) {
      return data
    }

    guard
      let data = try await self.underlyingDownloader.downloadPreferred(
        from: url)
    else {
      return nil
    }

    try? DiskCache.shared.insert(Data(contentsOf: data), forKey: origin)

    return data
  }

  func downloadPreferred(from url: URL) async throws -> URL? {
    guard let origin = url.host() else {
      throw FaviconDownloadError.invalidURL
    }

    if let data = DiskCache.shared.urlIfExists(forKey: origin) {
      return data
    }

    let urls = try await self.identifyIcons(from: url)
    print(urls)

    guard let url = urls.first else {
      logger.debug("Didn't find any favicons for url: \(url, privacy: .public)")
      return nil
    }

    return try await self.download(contentsOf: url)
  }
}

// TODO:
// @MainActor struct ChunkedFaviconDownloader: FaviconDownloader {
//   let underlyingDownloader: any FaviconDownloader
//   let parallelism: Int

//   let ongoing: [String] = []

//   init(underlyingDownloader: any FaviconDownloader, parallelism: Int = 5) {
//     self.underlyingDownloader = underlyingDownloader
//     self.parallelism = parallelism
//   }

//   func identifyIcons(from url: URL) async throws -> [URL] {
//     return try await self.underlyingDownloader.identifyIcons(from: url)
//   }

//   func download(contentsOf url: URL) async throws -> URL? {

//   }

//   func downloadPreferred(from url: URL) async throws -> URL? {

//   }
// }
