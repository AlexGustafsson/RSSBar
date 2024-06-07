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
      let modelContext = ModelContext(modelContainer)

      guard
        let feedIds = (try? modelContext.fetch(FetchDescriptor<Feed>()))?.map({
          $0.persistentModelID
        })
      else {
        return
      }

      for chunk in feedIds.chunked(into: 5) {
        await withTaskGroup(of: Void.self) { taskGroup in
          for feedId in chunk {
            taskGroup.addTask(operation: {
              let modelContext = ModelContext(modelContainer)

              let feed = modelContext.model(for: feedId) as! Feed

              let isOutdated =
                feed.lastUpdated == nil
                || feed.lastUpdated!.distance(to: Date())
                  > feed.updateInterval.timeInterval
              if ignoreSchedule || isOutdated {
                print(
                  "Updating \(feed.name)@\(feed.url.absoluteString) (ignoring schedule: \(ignoreSchedule), is outdated: \(isOutdated))"
                )
                do {
                  let result = try await RSSFeed(contentsOf: feed.url)
                  // TODO: Keep read date etc.
                  for item in result.entries {
                    let url = item.links.first
                    let newItem = FeedItem(
                      id: item.id,
                      title: item.title ?? "Item", date: Date(), read: nil,
                      url: url)
                    newItem.feed = feed
                    modelContext.insert(newItem)
                  }
                  feed.lastUpdated = Date()
                  modelContext.insert(feed)
                  try? modelContext.save()
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
      var image: NSImage = {
        let ratio = $0.size.height / $0.size.width
        $0.size.height = 18
        $0.size.width = 18 / ratio
        $0.isTemplate = true
        return $0
      }(Bundle.module.image(forResource: "icon.svg")!)

      Image(nsImage: image)
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
