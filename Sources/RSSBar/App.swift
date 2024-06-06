import RSSKit
import SettingsAccess
import SwiftData
import SwiftUI

@main
struct RSSBar: App {
  private let modelContainer: ModelContainer
  private let fetchFeeds: FetchFeedsAction
  private let timer: Timer

  init() {
    let modelContainer = try! ModelContainer(
      for: FeedGroup.self, Feed.self, FeedItem.self)
    self.modelContainer = modelContainer

    let fetchFeeds = FetchFeedsAction(action: { ignoreSchedule in
      let context = ModelContext(modelContainer)

      guard let feeds = try? context.fetch(FetchDescriptor<Feed>()) else {
        return
      }

      for chunk in feeds.chunked(into: 5) {
        await withTaskGroup(of: Void.self) { taskGroup in
          for feed in chunk {
            taskGroup.addTask(operation: {
              let context = ModelContext(modelContainer)

              let isOutdated =
                feed.lastUpdated == nil
                || feed.lastUpdated!.distance(to: Date())
                  > feed.updateInterval.timeInterval

              if ignoreSchedule || isOutdated {
                do {
                  let result = try await RSSFeed(download: feed.url)
                  // TODO: Keep read date etc.
                  for item in result.entries {
                    let url = item.links.first
                    let newItem = FeedItem(
                      id: item.id ?? url?.absoluteString ?? "<todo>",
                      title: item.title ?? "Item", date: Date(), read: nil,
                      url: url)
                    newItem.feed = feed
                    context.insert(newItem)
                  }
                  feed.lastUpdated = Date()
                  print(
                    "Feed updated \(feed.name)@\(feed.url.absoluteString): \(result.entries.count)"
                  )
                } catch {
                  print(
                    "Failed to update feed \(feed.name)@\(feed.url.absoluteString): \(error)"
                  )
                }
              }
            })
          }
        }
      }
    })
    self.fetchFeeds = fetchFeeds

    // Keep feeds up-to-date
    self.timer = Timer.scheduledTimer(
      withTimeInterval: 5 * 60, repeats: true,
      block: { timer in
        Task {
          await fetchFeeds(ignoreSchedule: false)
        }
      })
    self.timer.tolerance = 60
    RunLoop.current.add(self.timer, forMode: .common)

    // Trigger once
    self.timer.fire()
  }

  var body: some Scene {
    MenuBarExtra {
      MenuBarView().openSettingsAccess().modelContainer(
        modelContainer
      ).environment(
        \.fetchFeeds, self.fetchFeeds)
    } label: {
      Label("RSSBar", systemImage: "star")
    }.menuBarExtraStyle(.window)

    Window("About", id: "about") {
      AboutView()
    }
    .windowStyle(.hiddenTitleBar)
    .defaultPosition(.center)

    Settings {
      SettingsView().modelContainer(
        modelContainer
      ).environment(\.fetchFeeds, self.fetchFeeds)
    }
  }
}
