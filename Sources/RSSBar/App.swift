import AppKit
import RSSKit
import SettingsAccess
import SwiftData
import SwiftUI
import os

private let logger = Logger(
  subsystem: Bundle.main.bundleIdentifier!, category: "UI/App")

class AppState: ObservableObject {
  static let shared = AppState()

  @Published var icon: NSImage?
}

class AppDelegate: NSObject, NSApplicationDelegate {
  private var timer: Timer?

  private let database: any Database = SharedDatabase.shared.database

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    logger.info("Started RSSBar")
    DispatchQueue.main.async {
      NSApp.setActivationPolicy(.accessory)
    }

    self.render()

    // Keep feeds up-to-date
    self.timer = Timer.scheduledTimer(
      timeInterval: 5 * 60, target: self,
      selector: #selector(fireTimer), userInfo: nil, repeats: true)
    self.timer!.tolerance = 60
    RunLoop.current.add(self.timer!, forMode: .common)

    // Trigger once
    self.timer!.fire()
  }

  @MainActor func render() {
    Task {
      let count = try await self.database.countUnreadFeeds()

      let resource = Bundle.module.image(
        forResource: count == 0 ? "icon.svg" : "icon-with-banner.svg")!
      let ratio = resource.size.height / resource.size.width
      resource.size.height = 18
      resource.size.width = 18 / ratio
      resource.isTemplate = true
      AppState.shared.icon = resource
    }
  }

  @objc func fireTimer() {
    Task {
      try await fetchFeeds(ignoreSchedule: false)
    }
  }

  func fetchFeeds(ignoreSchedule: Bool) async throws {
    let feedIds = try await self.database.feedIds()

    for chunk in feedIds.chunked(into: 5) {
      await withThrowingTaskGroup(of: Void.self) { taskGroup in
        for feedId in chunk {
          taskGroup.addTask(operation: {
            guard let feed =
              try await self.database.fetch(feedId, for: Feed.self) else {
                return
              }

            let isOutdated =
              feed.lastUpdated == nil
              || feed.lastUpdated!.distance(to: Date()) > 1 * 60 * 60
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
                  feed.items.append(newItem)
                }
                feed.lastUpdated = Date()
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

    do {
      try await self.database.save()
    } catch {
      logger.error("Failed to save new items \(error)")
    }


    Task {
      await self.render()
    }
  }
}

@main struct RSSBar: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @StateObject var appState = AppState.shared

  // TODO: May be run several times, don't use it to start fetching feeds
  // TODO: Start task runner to load favicons on start. Then run on items and
  // feeds once they are added.

  var body: some Scene {
    MenuBarExtra {
      MenuBarView().openSettingsAccess()
        .modelContainer(SharedDatabase.shared.modelContainer)
        .environment(
          \.fetchFeeds, FetchFeedsAction(action: appDelegate.fetchFeeds)
        )
        .environment(
          \.updateIcon, UpdateIconAction(action: appDelegate.render)
        )
        .database(SharedDatabase.shared.database)
    } label: {
      if let icon = appState.icon {
        Image(nsImage: icon)
      }
    }
    .menuBarExtraStyle(.window)

    Window("About", id: "about") { AboutView() }.windowStyle(.hiddenTitleBar)
      .defaultPosition(.center)

    Settings {
      SettingsView().modelContainer(SharedDatabase.shared.modelContainer)
        .environment(
          \.fetchFeeds, FetchFeedsAction(action: appDelegate.fetchFeeds)
        )
        .environment(
          \.updateIcon, UpdateIconAction(action: appDelegate.render)
        )
        .onOpenURL { url in print(url) }
    }
    .database(SharedDatabase.shared.database)
  }
}
