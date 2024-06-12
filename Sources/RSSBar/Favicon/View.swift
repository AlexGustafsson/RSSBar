import SwiftUI
import os

private let logger = Logger(
  subsystem: Bundle.main.bundleIdentifier!, category: "UI/Favicon")

struct Favicon: View {
  public var url: URL?

  @State private var favicon: URL?
  @AppStorage("enableFaviconsFetching") private var enableFaviconsFetching =
    true

  var body: some View {
    AsyncImage(url: favicon) { image in
      image.resizable()
    } placeholder: {
      ZStack {
        Rectangle().fill(.gray).frame(width: .infinity, height: .infinity)
        if let url { Text(url.host()?.first?.description.uppercased() ?? "") }
      }
    }
    .mask(
      RoundedRectangle(cornerRadius: 6)
        .frame(
          width: .infinity, height: .infinity)
    )
    .onAppear {
      Task {
        if let url {
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
      }
    }
    .onDisappear {
      // TODO: Cancel download task (decrement number of interested parties as to not stop other favicon)?
    }
  }
}
