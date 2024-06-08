import SwiftUI
import os

private let logger = Logger(
  subsystem: Bundle.main.bundleIdentifier!, category: "UI/Favicon")

struct Favicon: View {
  public var url: URL?

  @State private var favicon: URL?

  var body: some View {
    // TODO: Always use a rounded rectangle as clipping mask
    AsyncImage(url: favicon) { image in
      image.resizable()
    } placeholder: {
      ZStack {
        RoundedRectangle(cornerRadius: 6).fill(.gray).frame(
          width: .infinity, height: .infinity)
        if let url {
          Text(url.host()?.first?.description.uppercased() ?? "")
        }
      }
    }.task {
      if let url {
        guard let origin = url.host() else {
          logger.error("Invalid host \(url.absoluteString, privacy: .public)")
          return
        }
        do {
          if let data = DiskCache.shared.urlIfExists(forKey: origin) {
            favicon = data
          } else {
            let urls = try await FaviconDownloader.identifyIcons(
              from: url.absoluteString)
            logger.debug("Identified urls: \(urls, privacy: .public)")
            if let url = urls.first {

              favicon = try await FaviconDownloader.download(contentsOf: url)
              if favicon != nil {
                do {
                  try DiskCache.shared.insert(
                    Data(contentsOf: favicon!), forKey: origin)
                } catch {
                  logger.error("Failed to cache content: \(error)")
                }
              }
            } else {
              logger.debug("No favicon found for URL")
            }
          }
        } catch {
          logger.error("Failed to fetch favicon: \(error)")
        }
      }
    }
  }
}
