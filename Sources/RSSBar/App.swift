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
  public var modelContainer: ModelContainer
  private var timer: Timer?

  override init() {
    do {
      self.modelContainer = try initializeModelContainer()
    } catch {
      logger.error("Failed to initialize model container \(error)")
      exit(1)
    }

    super.init()
  }

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
    let modelContext = ModelContext(self.modelContainer)

    let descriptor = FetchDescriptor<FeedItem>(
      predicate: #Predicate { $0.read == nil })
    let count = (try? modelContext.fetchCount(descriptor)) ?? 0

    let renderer = ImageRenderer(content: self.iconView(count: count))
    renderer.scale = 2.0
    AppState.shared.icon = renderer.nsImage
  }

  @objc func fireTimer() {
    Task {
      await fetchFeeds(ignoreSchedule: false)
    }
  }

  func fetchFeeds(ignoreSchedule: Bool) async {
    let modelContext = ModelContext(self.modelContainer)

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
            let modelContext = ModelContext(self.modelContainer)

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

    Task {
      await self.render()
    }
  }

  @ViewBuilder func iconView(count: Int) -> some View {
    let image: NSImage = {
      let ratio = $0.size.height / $0.size.width
      $0.size.height = 18
      $0.size.width = 18 / ratio
      $0.isTemplate = true
      return $0
    }(Bundle.module.image(forResource: "icon.svg")!)

    ZStack(alignment: .topTrailing) {
      Image(nsImage: image)
      if count > 0 {
        Circle().fill(.red).frame(width: 5, height: 5)
      }
    }
    .frame(width: 18, height: 18)
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
        .modelContainer(appDelegate.modelContainer)
        .environment(
          \.fetchFeeds, FetchFeedsAction(action: appDelegate.fetchFeeds)
        )
        .environment(
          \.updateIcon, UpdateIconAction(action: appDelegate.render))
    } label: {
      if let icon = appState.icon {
        Image(nsImage: icon)
      }
    }
    .menuBarExtraStyle(.window)

    Window("About", id: "about") { AboutView() }.windowStyle(.hiddenTitleBar)
      .defaultPosition(.center)

    Settings {
      SettingsView().modelContainer(appDelegate.modelContainer)
        .environment(
          \.fetchFeeds, FetchFeedsAction(action: appDelegate.fetchFeeds)
        )
        .environment(
          \.updateIcon, UpdateIconAction(action: appDelegate.render)
        )
        .onOpenURL { url in print(url) }
    }
  }
}
