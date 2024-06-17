import Combine
import Foundation
import SwiftData
import SwiftUI
import os

struct SettingsView: View {
  private enum Tabs: Hashable { case feeds, advanced }

  var body: some View {
    TabView {
      FeedsSettingsView().tabItem { Label("Feeds", systemImage: "list.bullet") }
        .tag(Tabs.feeds)
      AdvancedSettingsView()
        .tabItem {
          Label("Advanced", systemImage: "gearshape.2")
        }
        .tag(Tabs.advanced)
    }
    .padding(20).frame(width: 500, height: 720)
  }
}
