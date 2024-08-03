import AppKit
import RSSKit
import SettingsAccess
import SwiftData
import SwiftUI
import os

private let logger = Logger(
  subsystem: Bundle.main.bundleIdentifier!, category: "UI/App")

@MainActor class AppState: ObservableObject {
  static let shared = AppState()

  @Published var icon: NSImage?
}

class AppDelegate: NSObject, NSApplicationDelegate {
  private var timer: Timer?

  public let modelContainer: ModelContainer = try! ModelContainer.initDefault()

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
    guard let count = try? modelContext.countUnreadFeeds() else {
      return
    }
      let resource = Bundle.main.image(
      forResource: count == 0 ? "icon.svg" : "icon-with-banner.svg")!
    let ratio = resource.size.height / resource.size.width
    resource.size.height = 18
    resource.size.width = 18 / ratio
    resource.isTemplate = true
    AppState.shared.icon = resource
  }

  @MainActor @objc func fireTimer() {
    Task {
      let fetcher = FeedFetcher(modelContainer: self.modelContainer)
      do {
        try await fetcher.fetchFeeds()
      } catch {
        logger.error("Failed to fetch feeds: \(error, privacy: .public)")
      }
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
        .modelContainer(appDelegate.modelContainer)
        .environment(
          \.updateIcon, UpdateIconAction(action: appDelegate.render)
        )
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
          \.updateIcon, UpdateIconAction(action: appDelegate.render)
        )
        .onOpenURL { url in print(url) }
    }
  }
}
