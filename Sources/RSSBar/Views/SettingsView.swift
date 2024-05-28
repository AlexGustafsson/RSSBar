import Foundation
import SwiftUI

struct GeneralSettingsView: View {
  @AppStorage("showPreview") private var showPreview = true
  @AppStorage("fontSize") private var fontSize = 12.0

  var body: some View {
    Form {
      Toggle("Show Previews", isOn: $showPreview)
      Slider(value: $fontSize, in: 9...96) {
        Text("Font Size (\(fontSize, specifier: "%.0f") pts)")
      }
    }
    .padding(20)
    .frame(width: 350, height: 100)
  }
}

struct AdvancedSettingsView: View {
  @AppStorage("showPreview") private var showPreview = true
  @AppStorage("fontSize") private var fontSize = 12.0

  var body: some View {
    Form {
      Toggle("Show Previews", isOn: $showPreview)
      Slider(value: $fontSize, in: 9...96) {
        Text("Font Size (\(fontSize, specifier: "%.0f") pts)")
      }
    }
    .padding(20)
    .frame(width: 350, height: 100)
  }
}

struct FeedItemView: View {
  var body: some View {
    HStack {
      Favicon(
        url: URL(string: "https://github.com/releases/traefik.atom")!
      )
      .frame(
        width: 24, height: 24)

      VStack(alignment: .leading) {
        Text("Traefik releases")
        Text("github.com/releases/traefik.atom").font(.footnote)
          .foregroundStyle(.secondary)
      }.frame(maxWidth: .infinity, alignment: .topLeading)

      Button {

      } label: {
        Image(systemName: "info.circle").resizable().foregroundStyle(
          .secondary
        ).frame(
          width: 16, height: 16)
      }.buttonStyle(PlainButtonStyle())
    }.padding(4)
  }
}

struct FeedsSettingsView: View {
  @State private var filter: String = ""
  @FocusState var isFocused: Bool

  // TODO: insetGrouped: https://lucajonscher.medium.com/create-an-inset-grouped-list-in-swiftui-for-macos-20c0bcfaaa7
  var body: some View {
    Form {
      Section {
        HStack {
          // TODO: No way to replicate searchbar?
          // SEE: https://www.fullstackstanley.com/articles/replicating-the-macos-search-textfield-in-swiftui/
          HStack {
            Image(systemName: "magnifyingglass")
            TextField(
              "Search",
              text: $filter,
              prompt: Text("Search")
            )
            .labelsHidden()
            .disableAutocorrection(true)
            .onSubmit {
              print(filter)
            }.focused($isFocused)
          }

          Menu {
            Button("New feed") {

            }
            Button("New group") {

            }
          } label: {
            Image(systemName: "plus")
          }
          .fixedSize()

        }
      }

      Section("Updates") {
        List {
          FeedItemView()
          FeedItemView()
        }
      }

      Section("News") {
        List {
          FeedItemView()
          FeedItemView()
        }
      }
    }.formStyle(.grouped).padding(20)
  }
}

struct SettingsView: View {
  private enum Tabs: Hashable {
    case general, feeds, advanced
  }
  var body: some View {
    TabView {
      GeneralSettingsView()
        .tabItem {
          Label("General", systemImage: "gear")
        }
        .tag(Tabs.general)
      FeedsSettingsView()
        .tabItem {
          Label("Feeds", systemImage: "list.bullet")
        }
        .tag(Tabs.feeds)
      AdvancedSettingsView()
        .tabItem {
          Label("Advanced", systemImage: "gearshape.2")
        }
        .tag(Tabs.advanced)
    }
    .padding(20)
    .frame(width: 500, height: 720)
  }
}
