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

    Window("Settings", id: "settings") {
      SettingsView()
    }
  }
}

// do {
//   let applicationSupport = FileManager.default.urls(
//     for: .applicationSupportDirectory, in: .userDomainMask
//   ).first!
//   let bundleID = Bundle.main.bundleIdentifier ?? "company name"
//   let appSupportSubDirectory = applicationSupport.appendingPathComponent(
//     bundleID, isDirectory: true)
//   try FileManager.default.createDirectory(
//     at: appSupportSubDirectory, withIntermediateDirectories: true,
//     attributes: nil)
//   print(appSupportSubDirectory.path)  // /Users/.../Library/Application Support/YourBundleIdentifier
// } catch {
//   print(error)
// }
