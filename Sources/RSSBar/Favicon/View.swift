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
      let origin = url.host()!
      do {
        if let data = DiskCache.shared.urlIfExists(forKey: origin) {
          favicon = data
        } else {
          let urls = try await FaviconDownloader.identifyIcons(
            from: url.absoluteString)
          print(urls)
          if let url = urls.first {

            favicon = try await FaviconDownloader.download(contentsOf: url)
            do {
              try DiskCache.shared.insert(
                Data(contentsOf: favicon!), forKey: origin)
            } catch {
              print("Failed to cache content \(error)")
            }
          } else {
            // TODO: Log
            print("No favicon")
          }
        }
      } catch {
        // TODO: Log
        print("Failed to fetch favicon! \(error)")
      }

    }
  }
}
