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
    .frame(width: 350, height: 100)
  }
}

struct FeedItemDetailsView: View {
  @State var feed: FeedModel
  @State var newName = ""
  @State var newUrl = ""
  @State var editing = false
  @State var presentDeleteAlert = false

  @Environment(\.dismiss) var dismiss

  var body: some View {
    VStack(spacing: 0) {
      Form {
        Section {
          HStack {
            Favicon(
              url: feed.url
            )
            .frame(
              width: 48, height: 48)
            VStack(alignment: .leading) {
              if editing {
                TextField("Name", text: $newName, prompt: Text(feed.name))
                  .textFieldStyle(.plain)
                  .labelsHidden().font(.headline)
              } else {
                Text(feed.name).font(.headline)
              }
              Text("Last fetched 17:25").font(.footnote)
                .foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity, alignment: .topLeading)
          }

          LabeledContent("Feed") {
            if editing {
              TextField(
                "Feed", text: $newUrl, prompt: Text(feed.url.absoluteString)
              )
              .labelsHidden()
            } else {
              Text(verbatim: feed.url.absoluteString)
            }
          }
        }

        Section("Options") {
          List {
            Picker("Update interval", selection: $feed.updateInterval) {
              Text("Default")
              Text("Hourly")
              Text("Daily")
              Text("Weekly")
              Text("Monthly")
            }

            Button("Clear history", role: .destructive) {

            }
          }
        }
      }.padding(20).formStyle(.grouped)

      Divider()

      // Footer
      HStack {
        Button("Delete feed...") {
          presentDeleteAlert = true
        }.confirmationDialog(
          "Are you sure you want to delete this feed?",
          isPresented: $presentDeleteAlert
        ) {
          Button("Delete feed", role: .destructive) {
            dismiss()
          }.keyboardShortcut(.delete)
        } message: {
          Text(
            "The feed will be removed, along with the history of read entries.")
        }.dialogIcon(Image(systemName: "trash.circle.fill"))

        Spacer()
        Button(editing ? "Cancel" : "Edit") {
          editing = !editing
        }.keyboardShortcut(editing ? .cancelAction : nil)
        Button(editing ? "Save" : "Done") {
          if editing {
            editing = !editing
          } else {
            dismiss()
          }
        }.keyboardShortcut(.defaultAction)
      }.padding(20)
    }
  }
}

struct FeedItemView: View {
  @State var feed: FeedModel

  @State private var shouldPresentSheet = false

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
        shouldPresentSheet.toggle()
      } label: {
        Image(systemName: "info.circle").resizable().foregroundStyle(
          .secondary
        ).frame(
          width: 16, height: 16)
      }.buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $shouldPresentSheet) {
          print("Sheet dismissed!")
        } content: {
          FeedItemDetailsView(feed: feed)
        }
    }.padding(4)
  }
}

struct FeedGroupView: View {
  @State var group: FeedGroupModel

  @State private var presentDeleteAlert: Bool = false
  @State private var presentPrompt: Bool = false

  @State private var newName: String = ""

  var body: some View {
    Section(group.name) {
      List {
        ForEach(group.feeds, id: \.id) { feed in
          FeedItemView(feed: feed)
        }
      }

      HStack {
        Spacer()
        Menu {
          Button("Add feed") {

          }
          Button("Move up") {

          }
          Button("Move down") {

          }
          Button("Edit name") {
            presentPrompt = true
          }
          Button("Delete", role: .destructive) {
            presentDeleteAlert = true
          }
        } label: {
          Image(systemName: "ellipsis")
        }
        .fixedSize()
        .confirmationDialog(
          "Are you sure you want to delete this group?",
          isPresented: $presentDeleteAlert
        ) {
          Button("Delete group", role: .destructive) {
            // TOOD
          }.keyboardShortcut(.delete)
        } message: {
          Text(
            "The group will be removed, along with all of the feeds it contains."
          )
        }.dialogIcon(Image(systemName: "trash.circle.fill"))
        .alert("Edit group name", isPresented: $presentPrompt) {
          TextField("Name", text: $newName, prompt: Text(group.name))
          // NOTE: Don't ask why, but this button has to be here. If it's not,
          // there'll be a default OK button anyway that works, but without it
          // the TextField is not shown
          Button("OK") {}
        }.dialogIcon(Image(systemName: "textformat.abc"))
      }
    }

  }
}

struct FeedsSettingsView: View {
  @State private var filter: String = ""
  @FocusState var isFocused: Bool
  @State var presentPrompt: Bool = false
  @State var newName: String = ""
  @Environment(\.feedData) private var feedData

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
            Button("New group") {
              presentPrompt = true
            }
          } label: {
            Image(systemName: "plus")
          }
          .fixedSize().alert("Add new group", isPresented: $presentPrompt) {
            TextField("Name", text: $newName, prompt: Text("Group name"))
            // NOTE: Don't ask why, but this button has to be here. If it's not,
            // there'll be a default OK button anyway that works, but without it
            // the TextField is not shown
            Button("OK") {}
          } message: {
            Text("Select a name for the new group.")
          }.dialogIcon(Image(systemName: "textformat.abc"))

        }
      }

      ForEach(feedData.groups, id: \.id) { group in
        FeedGroupView(group: group)
      }
    }.formStyle(.grouped)
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
