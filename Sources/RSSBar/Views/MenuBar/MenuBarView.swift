import Foundation
import SwiftData
import SwiftUI
import os

private let logger = Logger(
  subsystem: Bundle.main.bundleIdentifier!, category: "UI/MenuBar")

struct MenuBarView: View {
  @Environment(\.openWindow) private var openWindow
  @Environment(\.closeMenuBar) private var closeMenuBar
  @Environment(\.quitApp) private var quitApp
  @Environment(\.openSettings) private var openSettings
  @Environment(\.fetchFeeds) private var fetchFeeds
  @Environment(\.updateIcon) var updateIcon
  @Environment(\.modelContext) var modelContext

  @Query(sort: \FeedGroup.order) var groups: [FeedGroup]
  @Query var feedItems: [FeedItem]

  var body: some View {
    VStack(alignment: .leading) {
      MenuBarTextItem(
        title: "Fetch now"
      ) {
        Task { await fetchFeeds?(ignoreSchedule: true) }
      }
      MenuBarTextItem(
        title: "Mark all as read"
      ) {
        for item in feedItems {
          item.read = item.read ?? Date()
        }
        do {
          try modelContext.save()
        } catch {
          logger.error("Failed to mark all items as read \(error)")
        }
        updateIcon?()
      }

      Divider()

      // Feeds
      ForEach(groups, id: \.id) { group in
        if group.name != "" {
          MenuBarSectionHeader(group.name)
        }
        LazyVStack(alignment: .leading, spacing: 0) {
          ForEach(group.feeds, id: \.id) { feed in MenuBarFeedItem(feed: feed) }
        }
        Divider()
      }

      // Footer
      VStack(alignment: .leading, spacing: 0) {
        // About
        MenuBarTextItem(title: "About") {
          openWindow(id: "about")
          closeMenuBar()

          DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
          }
        }

        // Settings
        MenuBarTextItem(title: "Settings...") {
          try? openSettings()
          closeMenuBar()

          DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
          }
        }

        // Quit
        MenuBarTextItem(title: "Quit") {
          quitApp()
          closeMenuBar()
        }
      }
    }
    .padding(EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6))
  }
}
