import SwiftUI

struct Favicon: View {
  public let url: URL

  @State private var favicon: URL?

  var body: some View {
    AsyncImage(url: favicon) { image in
      image.resizable()
    } placeholder: {
      Image(systemName: "newspaper.circle.fill").resizable()
    }.task {
      // TODO: Cache
      do {
        let urls = try await FaviconDownloader.identifyIcons(
          from: url.absoluteString)
        print(urls)
        if let url = urls.first {
          favicon = try await FaviconDownloader.download(contentsOf: url)
        } else {
          // TODO: Log
          print("No favicon")
        }
      } catch {
        // TODO: Log
        print("Failed to fetch favicon! \(error)")
      }

    }
  }
}
