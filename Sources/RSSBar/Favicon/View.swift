import SwiftUI
import os

private let logger = Logger(
  subsystem: Bundle.main.bundleIdentifier!, category: "UI/Favicon")

struct Favicon: View {
  public var url: URL?
  public var fallbackCharacter: String?
  public var fallbackSystemName: String?

  @State private var favicon: URL?
  @AppStorage(UserDefaults.Keys.enableFaviconsFetching.rawValue) private
    var enableFaviconsFetching =
    true

  func fetchURL() {
    if let url {
      Task {
        do {
          favicon = try await CachedFaviconDownloader(
            underlyingDownloader: BasicFaviconDownloader(),
            cacheOnly: !enableFaviconsFetching
          )
          .downloadPreferred(from: url)
        } catch {
          logger.error(
            "Failed to fetch favicon for \(url, privacy: .public): \(error)")
        }
      }
    } else {
      self.favicon = nil
    }
  }

  var body: some View {
    AsyncImage(url: favicon) { image in
      image.resizable()
    } placeholder: {
      ZStack {
        Rectangle().fill(.gray)
        if let fallbackCharacter, fallbackCharacter != "" {
          Text(
            fallbackCharacter.first?
              .description.uppercased() ?? ""
          )
        } else if let fallbackSystemName {
          Image(systemName: fallbackSystemName)
        } else {
          Text(
            url?.host()?
              .first?
              .description.uppercased() ?? "")
        }
      }
    }
    .mask(
      RoundedRectangle(cornerRadius: 6)
    )
    .onChange(of: url) { _, url in
      fetchURL()
    }
    .onAppear {
      fetchURL()
    }
    .onDisappear {
      // TODO: Cancel download task (decrement number of interested parties as to not stop other favicon)?
    }
  }
}

#Preview {
    VStack {
        Favicon(fallbackCharacter: "C").frame(width: 24, height: 24)
        Favicon(fallbackCharacter: "F").frame(width: 24, height: 24)
        Favicon(fallbackSystemName: "rectangle.portrait.and.arrow.right").frame(width: 24, height: 24)
        Favicon(url: URL(string: "https://example.com")).frame(width: 24, height: 24)
    }.padding(20)
}
