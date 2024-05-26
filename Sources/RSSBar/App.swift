import SwiftUI

@main
struct RSSBar: App {
  @State var closeMenuBar: Bool = false

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
  }
}
