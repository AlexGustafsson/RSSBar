import SwiftUI

// SEE: https://github.com/feedback-assistant/reports/issues/383
// SEE: https://github.com/feedback-assistant/reports/issues/328

public struct CloseMenuBarAction {
  @MainActor public func callAsFunction() {
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
  @MainActor public func callAsFunction() { NSApplication.shared.terminate(nil) }
}

extension NSStatusItem {
  /// Close a StatusItem by simulating the click of a menu item.
  @MainActor public func close() {
    let actionSelector = button?.action
    button?.sendAction(actionSelector, to: button?.target)
  }
}

extension EnvironmentValues {
  public var closeMenuBar: CloseMenuBarAction { return CloseMenuBarAction() }
}

extension EnvironmentValues {
  public var quitApp: QuitAppAction { return QuitAppAction() }

  // TODO: Use @Entry of Swift 6?
  var updateIcon: UpdateIconAction {
    get { self[UpdateIconActionKey.self] }
    set { self[UpdateIconActionKey.self] = newValue }
  }
}

struct UpdateIconAction: Sendable {
  typealias Action = @Sendable () -> Void
  let action: Action
  func callAsFunction() {
    action()
  }
}

private struct UpdateIconActionKey: EnvironmentKey {
  static let defaultValue: UpdateIconAction = UpdateIconAction(action: {assertionFailure("Update icon action not set")})
}
