import AppKit

class RSSBarMenu: NSObject {
  private var statusItem: NSStatusItem!
  private var menu: NSMenu!

  private let applicationName =
    Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? ""

  typealias MenuItemClickedCallback = () -> Void
  var onCheckNow: MenuItemClickedCallback = {}
  var onShowAbout: MenuItemClickedCallback = {}
  var onAddFeed: MenuItemClickedCallback = {}
  var onMarkAllAsRead: MenuItemClickedCallback = {}
  var onQuit: MenuItemClickedCallback = {}

  override init() {
    super.init()

    self.statusItem = NSStatusBar.system.statusItem(
      withLength: NSStatusItem.variableLength)
    self.statusItem.button?.title = "⌘"

    self.menu = NSMenu()

    // Check now
    self.menu
      .addItem(
        NSMenuItem(
          title: "Check now",
          action: #selector(self.checkNow),
          target: self,
          keyEquivalent: ""
        ))
    // --
    self.menu.addItem(NSMenuItem.separator())
    // Add feed
    self.menu
      .addItem(
        NSMenuItem(
          title: "Add feed",
          action: #selector(self.addFeed),
          target: self,
          keyEquivalent: ""
        ))
    // --
    self.menu.addItem(NSMenuItem.separator())
    // About RSSBar
    self.menu
      .addItem(
        NSMenuItem(
          title: "About \(self.applicationName)",
          action: #selector(self.showAbout),
          target: self,
          keyEquivalent: ""
        ))
    // Quit RSSBar
    self.menu.addItem(
      NSMenuItem(
        title: "Quit \(self.applicationName)", action: #selector(self.quit),
        target: self,
        keyEquivalent: "")
    )
    // --
    self.menu.addItem(NSMenuItem.separator())
    // Mark all as read
    self.menu.addItem(
      NSMenuItem(
        title: "Mark all as read",
        action: #selector(self.markAllAsRead),
        target: self,
        keyEquivalent: ""
      )
    )

    self.statusItem.menu = self.menu
  }

  @objc func checkNow() {
    self.onCheckNow()
  }

  @objc func addFeed() {
    self.onAddFeed()
  }

  @objc func showAbout() {
    self.onShowAbout()
  }

  @objc func markAllAsRead() {
    self.onMarkAllAsRead()
  }

  @objc func quit() {
    self.onQuit()
  }
}
