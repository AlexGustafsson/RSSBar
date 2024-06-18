import RSSKit
import SettingsAccess
import SwiftData
import SwiftUI
import os

private let logger = Logger(
  subsystem: Bundle.main.bundleIdentifier!, category: "UI/App")

@main struct RSSBar: App {
  private let modelContainer: ModelContainer
  private let fetchFeeds: FetchFeedsAction
  private let timer: Timer

  // TODO: May be run several times, don't use it to start fetching feeds
  // TODO: Start task runner to load favicons on start. Then run on items and
  // feeds once they are added.
  init() {
    logger.info("Starting RSSBar")

    DispatchQueue.main.async {
      NSApp.setActivationPolicy(.accessory)
    }

    let modelContainer: ModelContainer
    do {
      modelContainer = try initializeModelContainer()
    } catch {
      logger.error("Failed to initialize model container \(error)")
      exit(1)
    }
    // Keep local reference which is used in threads later on to deal with
    // escaping self reference
    self.modelContainer = modelContainer

    let fetchFeeds = FetchFeedsAction(action: { ignoreSchedule in
      let modelContext = ModelContext(modelContainer)

      guard
        let feedIds = (try? modelContext.fetch(FetchDescriptor<Feed>()))?
          .map({
            $0.persistentModelID
          })
      else { return }

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
                logger.debug(
                  "Updating \(feed.name, privacy: .public)@\(feed.url.absoluteString, privacy: .public) (ignoring schedule: \(ignoreSchedule), is outdated: \(isOutdated))"
                )
                do {
                  let result = try await RSSFeed(contentsOf: feed.url)
                  for item in result.entries {
                    let id = UUID.v8(withHash: "\(feed.id):\(item.id)")

                    let oldItem = feed.items.first(where: {
                      $0.id == id
                    })

                    let newItem = FeedItem(
                      id: id,
                      title: item.title ?? item.summary ?? "Feed item",
                      date: item.updated,
                      read: oldItem?.read,
                      url: item.links.first
                    )
                    newItem.feed = feed

                    modelContext.insert(newItem)
                  }
                  feed.lastUpdated = Date()
                  modelContext.insert(feed)
                  do {
                    try modelContext.save()
                  } catch {
                    logger.error("Failed to save new items \(error)")
                  }
                  logger.debug(
                    "Feed updated \(feed.name, privacy: .public)@\(feed.url.absoluteString, privacy: .public): \(result.entries.count)"
                  )
                } catch {
                  logger.debug(
                    "Failed to update feed \(feed.name, privacy: .public)@\(feed.url.absoluteString, privacy: .public): \(error)"
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
      block: { timer in Task { await fetchFeeds(ignoreSchedule: false) } })
    self.timer.tolerance = 60
    RunLoop.current.add(self.timer, forMode: .common)

    // Trigger once
    self.timer.fire()
  }

  var body: some Scene {
    MenuBarExtra {
      MenuBarView().openSettingsAccess().modelContainer(modelContainer)
        .environment(\.fetchFeeds, self.fetchFeeds)
    } label: {
      let image: NSImage = {
        let ratio = $0.size.height / $0.size.width
        $0.size.height = 18
        $0.size.width = 18 / ratio
        $0.isTemplate = true
        return $0
      }(Bundle.module.image(forResource: "icon.svg")!)

      Image(nsImage: image)
    }
    .menuBarExtraStyle(.window)

    Window("About", id: "about") { AboutView() }.windowStyle(.hiddenTitleBar)
      .defaultPosition(.center)

    Settings {
      SettingsView().modelContainer(modelContainer)
        .environment(
          \.fetchFeeds, self.fetchFeeds
        )
        .onOpenURL { url in print(url) }
    }
  }
}
