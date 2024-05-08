import AppKit
import SwiftUI

class AddFeedViewController {
  private let window: NSWindow!
  private let applicationName =
    Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? ""

  init() {
    let contentView = AddFeedView()
    self.window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 345, height: 245),
      styleMask: [.titled, .closable],
      backing: .buffered,
      defer: false
    )
    self.window.isReleasedWhenClosed = false
    self.window.level = .normal
    self.window.contentView = NSHostingView(rootView: contentView)
    self.window.title = "RSSBar"
    self.window.styleMask.insert(.resizable)
    self.window.center()
  }

  public func show() {
    NSApp.activate(ignoringOtherApps: true)
    self.window.makeKeyAndOrderFront(nil)
  }

  public func hide() {
    self.window.orderOut(nil)
  }
}
