import AppKit
import SwiftUI
import os

private let logger = Logger(
  subsystem: Bundle.main.bundleIdentifier!, category: "UI/AppDelegate")

struct HistoryItem {
  let command: String
  let executionTime: Date
}

class AppDelegate: NSObject, NSApplicationDelegate {
  private var menu: RSSBarMenu?

  func applicationDidFinishLaunching(_: Notification) {
    self.menu = self.createMenu()
  }

  private func createMenu() -> RSSBarMenu {
    let menu = RSSBarMenu()
    menu.onQuit = {
      NSApplication.shared.terminate(nil)
    }
    menu.onCheckNow = {
      // TODO
    }
    menu.onShowAbout = {
      let viewController = AboutViewController()
      viewController.show()
    }
    menu.onAddFeed = {
      let viewController = AddFeedViewController()
      viewController.show()

    }
    menu.onMarkAllAsRead = {
      // TODO
    }
    return menu
  }

  func applicationWillTerminate(_: Notification) {
    // Do nothing for now
  }

  func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool
  {
    // Menu bar app
    false
  }
}
