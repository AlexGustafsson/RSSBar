import SwiftUI

// SEE: https://github.com/feedback-assistant/reports/issues/383
// SEE: https://github.com/feedback-assistant/reports/issues/328

public struct CloseMenuBarAction {
  public func callAsFunction() {
    let statusItems = NSApp.windows
      .filter {
        $0.className.contains("NSStatusBarWindow")
      }
      .compactMap { window -> NSStatusItem? in
        guard
          let statusItem = window.value(forKeyPath: "statusItem")
            as? NSStatusItem, statusItem.className == "NSStatusItem"
        else { return nil }
        return statusItem
      }

    for statusItem in statusItems { statusItem.close() }
  }
}

public struct QuitAppAction {
  public func callAsFunction() { NSApplication.shared.terminate(nil) }
}

public struct FetchFeeds {
  public func callAsFunction() { NSApplication.shared.terminate(nil) }
}

extension NSStatusItem {
  /// Close a StatusItem by simulating the click of a menu item.
  public func close() {
    let actionSelector = button?.action
    button?.sendAction(actionSelector, to: button?.target)
  }
}

extension EnvironmentValues {
  public var closeMenuBar: CloseMenuBarAction { return CloseMenuBarAction() }
}

extension EnvironmentValues {
  public var quitApp: QuitAppAction { return QuitAppAction() }

  var fetchFeeds: FetchFeedsAction? {
    get { self[FetchFeedsActionKey.self] }
    set { self[FetchFeedsActionKey.self] = newValue }
  }

  var updateIcon: UpdateIconAction? {
    get { self[UpdateIconActionKey.self] }
    set { self[UpdateIconActionKey.self] = newValue }
  }
}

struct FetchFeedsAction {
  typealias Action = (Bool) async throws -> Void
  let action: Action
  func callAsFunction(ignoreSchedule: Bool) async throws {
    try await action(ignoreSchedule)
  }
}

private struct FetchFeedsActionKey: EnvironmentKey {
  static var defaultValue: FetchFeedsAction? = nil
}

struct UpdateIconAction {
  typealias Action = () -> Void
  let action: Action
  func callAsFunction() {
    action()
  }
}

private struct UpdateIconActionKey: EnvironmentKey {
  static var defaultValue: UpdateIconAction? = nil
}
