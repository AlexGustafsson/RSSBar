import SettingsAccess
import SwiftData
import SwiftUI

@main
struct RSSBar: App {
  @State private var container = try! ModelContainer(
    for: FeedGroup.self, Feed.self, FeedItem.self)

  // private var feedData = FeedDataModel(
  //   groups: [
  //     FeedGroupModel(
  //       name: "",
  //       feeds: [
  //         FeedModel(
  //           id: "1",
  //           url: URL(string: "https://github.com/releases/traefik.atom")!,
  //           name: "Traefik releases",
  //           items: [
  //             FeedItemModel(
  //               id: "1", title: "v1.0.2", date: Date(), read: false,
  //               url: URL(
  //                 string:
  //                   "https://github.com/traefik/traefik/releases/tag/v3.0.1"
  //               )!),
  //             FeedItemModel(
  //               id: "2", title: "v1.0.1", date: Date(), read: true,
  //               url: URL(
  //                 string:
  //                   "https://github.com/traefik/traefik/releases/tag/v3.0.1"
  //               )!),
  //             FeedItemModel(
  //               id: "3", title: "v1.0.0", date: Date(), read: true,
  //               url: URL(
  //                 string:
  //                   "https://github.com/traefik/traefik/releases/tag/v3.0.1"
  //               )!),
  //           ])
  //       ]),
  //     FeedGroupModel(
  //       name: "News",
  //       feeds: [
  //         FeedModel(
  //           id: "1",
  //           url: URL(string: "https://github.com/releases/traefik.atom")!,
  //           name: "Traefik releases",
  //           items: [
  //             FeedItemModel(
  //               id: "1", title: "v1.0.2", date: Date(), read: false,
  //               url: URL(
  //                 string:
  //                   "https://github.com/traefik/traefik/releases/tag/v3.0.1"
  //               )!),
  //             FeedItemModel(
  //               id: "2", title: "v1.0.1", date: Date(), read: true,
  //               url: URL(
  //                 string:
  //                   "https://github.com/traefik/traefik/releases/tag/v3.0.1"
  //               )!),
  //             FeedItemModel(
  //               id: "3", title: "v1.0.0", date: Date(), read: true,
  //               url: URL(
  //                 string:
  //                   "https://github.com/traefik/traefik/releases/tag/v3.0.1"
  //               )!),
  //           ])
  //       ]),
  //   ]
  // )

  var body: some Scene {
    MenuBarExtra {
      MenuBarView().openSettingsAccess().modelContainer(container)
    } label: {
      Label("RSSBar", systemImage: "star")
    }.menuBarExtraStyle(.window)

    Window("About", id: "about") {
      AboutView()
    }
    .windowStyle(.hiddenTitleBar)
    .defaultPosition(.center)

    Settings {
      SettingsView().modelContainer(container)
    }
  }
}
