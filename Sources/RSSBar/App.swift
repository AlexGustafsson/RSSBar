import SwiftUI

@main
struct RSSBar: App {
  var body: some Scene {
    MenuBarExtra {
      MenuBarView()
    } label: {
      Label("RSSBar", systemImage: "star")
    }.menuBarExtraStyle(.window)

    Window("About", id: "about") {
      AboutView()
    }
    .windowStyle(.hiddenTitleBar)
    .defaultPosition(.center)

    Window("Settings", id: "settings") {
      SettingsView()
    }

  }
}
