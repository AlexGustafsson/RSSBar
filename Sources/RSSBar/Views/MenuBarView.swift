import Foundation
import SwiftData
import SwiftUI

struct MenuBarView: View {
  @Environment(\.openWindow) private var openWindow
  @Environment(\.closeMenuBar) private var closeMenuBar
  @Environment(\.quitApp) private var quitApp
  @Environment(\.openSettings) private var openSettings
  @Environment(\.fetchFeeds) private var fetchFeeds

  @Query(sort: \FeedGroup.order) var groups: [FeedGroup]

  @State private var hoveredListItem: Int?

  var body: some View {
    VStack(alignment: .leading) {
      MenuBarTextItem(
        action: { Task { await fetchFeeds?(ignoreSchedule: true) } },
        title: "Fetch now")

      Divider()

      ForEach(groups, id: \.id) { group in
        if group.name != "" {
          Text(group.name).fontWeight(.bold)
            .frame(
              maxWidth: .infinity, alignment: .leading
            )
            .font(.subheadline)
            .padding(
              EdgeInsets(top: 2, leading: 6, bottom: 0, trailing: 0)
            )
            .foregroundStyle(.secondary)
        }
        LazyVStack(alignment: .leading, spacing: 0) {
          ForEach(group.feeds, id: \.id) { feed in MenuBarFeedItem(feed: feed) }
        }
        Divider()
      }

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
    }
    .padding(EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6))
  }
}
