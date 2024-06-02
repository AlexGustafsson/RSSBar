import Foundation
import SwiftUI

struct MenuBarView: View {
  @Environment(\.openWindow) private var openWindow
  @Environment(\.closeMenuBar) private var closeMenuBar
  @Environment(\.quitApp) private var quitApp
  @Environment(\.openSettings) private var openSettings

  @State private var hoveredListItem: Int?

  var body: some View {
    VStack(alignment: .leading) {
      MenuBarTextItem(
        action: {
          // TODO
          closeMenuBar()
        },
        title: "Fetch now"
      )

      Divider()

      LazyVStack(alignment: .leading, spacing: 0) {
        MenuBarFeedItem(
          title: "GitHub", url: URL(string: "https://github.com")!)
        MenuBarFeedItem(
          title: "Hacker News",
          url: URL(string: "https://news.ycombinator.com")!)
      }

      Divider()

      Text("News").fontWeight(.bold).frame(
        maxWidth: .infinity, alignment: .leading
      ).font(.subheadline).padding(
        EdgeInsets(top: 2, leading: 6, bottom: 0, trailing: 0)
      ).foregroundStyle(.secondary)
      LazyVStack(alignment: .leading, spacing: 0) {
        MenuBarFeedItem(
          title: "GitHub", url: URL(string: "https://github.com")!)
        MenuBarFeedItem(
          title: "Hacker News",
          url: URL(string: "https://news.ycombinator.com")!)

      }

      Divider()

      Text("Tech").fontWeight(.bold).frame(
        maxWidth: .infinity, alignment: .leading
      ).font(.subheadline).padding(
        EdgeInsets(top: 2, leading: 6, bottom: 0, trailing: 0)
      ).foregroundStyle(
        .secondary
      )
      LazyVStack(alignment: .leading, spacing: 0) {
        MenuBarFeedItem(
          title: "GitHub", url: URL(string: "https://github.com")!)
        MenuBarFeedItem(
          title: "Hacker News",
          url: URL(string: "https://news.ycombinator.com")!)

      }

      Divider()

      VStack(alignment: .leading, spacing: 0) {
        MenuBarTextItem(
          action: {
            openWindow(id: "about")
            closeMenuBar()

          }, title: "About")
        MenuBarTextItem(
          action: {
            try? openSettings()
            closeMenuBar()

          }, title: "Settings...")
        MenuBarTextItem(
          action: {
            quitApp()
            closeMenuBar()
          }, title: "Quit")
      }
    }.padding(
      EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
    )
  }
}
