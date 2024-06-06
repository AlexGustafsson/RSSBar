import SwiftUI

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
          print("Invalid host \(url.absoluteString)")
          return
        }
        do {
          if let data = DiskCache.shared.urlIfExists(forKey: origin) {
            favicon = data
          } else {
            let urls = try await FaviconDownloader.identifyIcons(
              from: url.absoluteString)
            print(urls)
            if let url = urls.first {

              favicon = try await FaviconDownloader.download(contentsOf: url)
              if favicon != nil {
                do {
                  try DiskCache.shared.insert(
                    Data(contentsOf: favicon!), forKey: origin)
                } catch {
                  print("Failed to cache content \(error)")
                }
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
}
