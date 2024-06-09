import Combine
import Foundation
import SwiftData
import SwiftUI
import os

private let logger = Logger(
  subsystem: Bundle.main.bundleIdentifier!, category: "UI/Settings")

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
  @State private var presentResetDialog = false

  @Environment(\.modelContext) var modelContext

  var body: some View {
    Form {
      Section("Actions") {
        Button("Reset...") {
          presentResetDialog = true
        }.confirmationDialog(
          "Are you sure you want to reset all settings and data?",
          isPresented: $presentResetDialog
        ) {
          Button("Reset", role: .destructive) {
            do {
              // NOTE: Should coalesce delete on FeedGroup and Feed, but let's
              // make sure all potential dangling items are deleted as well
              try modelContext.delete(model: FeedGroup.self)
              try modelContext.delete(model: Feed.self)
              try modelContext.delete(model: FeedItem.self)
              // TODO: Reset settings to default
            } catch {
              logger.error("Failed to clear data")
            }
          }.keyboardShortcut(.delete)
        } message: {
          Text(
            "The feed will be removed, along with the history of read entries.")
        }.dialogIcon(Image(systemName: "arrow.clockwise.circle.fill"))

      }
    }.formStyle(.grouped)
  }
}

struct FeedItemDetailsView: View {
  @State var feed: Feed
  @State var newName = ""
  @State var newURL = ""
  @State var newUpdateInterval = ""
  @State var editing = false
  @State var presentDeleteAlert = false

  @State private var newURLValidated = false

  @Environment(\.modelContext) var modelContext
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
                "Feed", text: $newURL, prompt: Text(feed.url.absoluteString)
              )
              .labelsHidden().onReceive(
                Just(newURL)
              ) { newURL in
                guard let url = URL(string: newURL) else {
                  newURLValidated = false
                  return
                }

                let isHTTP = url.scheme?.hasPrefix("http") ?? false
                let isHTTPS = url.scheme?.hasPrefix("https") ?? false
                let hasDomain = url.host() != nil
                newURLValidated = (isHTTP || isHTTPS) && hasDomain
              }
            } else {
              Text(verbatim: feed.url.absoluteString)
            }
          }
          LabeledContent("Items") {
            Text("\(feed.items.count)")
          }
          LabeledContent("Unread items") {
            Text("\(feed.unreadItemsCount)")
          }
        }

        Section("Options") {
          List {
            if editing {
              Picker("Update interval", selection: $newUpdateInterval) {
                Text("Default")
                Text("Hourly")
                Text("Daily")
                Text("Weekly")
                Text("Monthly")
              }
            } else {
              LabeledContent("Update interval") {
                Text("Default")
              }
            }
          }
        }

        Section("Actions") {
          List {
            Button("Clear history", role: .destructive) {
              for item in feed.items {
                item.read = nil
              }
              try? modelContext.save()
            }
          }
        }

        Section("Items") {
          List {
            ForEach(
              feed.items.sorted(by: {
                ($0.date ?? Date()) > ($1.date ?? Date())
              }), id: \.id
            ) { item in
              HStack(alignment: .center) {
                Favicon(url: item.url).frame(width: 24, height: 24)
                VStack(alignment: .leading) {
                  Text(item.title).foregroundColor(.primary)
                  Text(item.date?.formattedDistance(to: Date()) ?? "")
                    .foregroundColor(
                      .primary
                    ).font(.footnote)
                }.frame(maxWidth: .infinity, alignment: .topLeading)
                Button {
                  if item.url != nil {
                    NSWorkspace.shared.open(item.url!)
                    item.read = Date()
                    try? modelContext.save()
                  }
                } label: {
                  Image(
                    systemName: "rectangle.portrait.and.arrow.right"
                  ).resizable().foregroundStyle(
                    .secondary
                  ).frame(
                    width: 16, height: 16)
                }.buttonStyle(PlainButtonStyle())
              }.opacity(item.read == nil ? 1.0 : 0.6)
            }
            if feed.items.count == 0 {
              Text("No items")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(10).font(.callout)
                .foregroundStyle(.secondary).frame(width: .infinity)
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
            withAnimation {
              let group = feed.group!
              var s = group.feeds.sorted(by: { $0.order < $1.order })
              s.remove(at: feed.order)
              for (index, item) in s.enumerated() {
                item.order = index
              }
              group.feeds = s

              try? modelContext.save()

              dismiss()
            }
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
            withAnimation {
              if newName != "" {
                feed.name = newName
              }
              if newURL != "" {
                feed.url = URL(string: newURL)!
              }
              // TODO: Update interval
              try? modelContext.save()
            }
            editing = !editing
          } else {
            dismiss()
          }
        }.keyboardShortcut(.defaultAction).disabled(
          editing && (newURL != "" && !newURLValidated))
      }.padding(20)
    }
  }
}

struct AddFeedAlertView: View {
  @State var group: FeedGroup

  @Environment(\.modelContext) var modelContext
  @Environment(\.dismiss) var dismiss
  @Environment(\.fetchFeeds) var fetchFeeds

  @State private var newName: String = ""
  @State private var newNameValidated = false
  @State private var newURL: String = ""
  @State private var newURLValidated = false

  var body: some View {
    VStack {
      TextField("Name", text: $newName, prompt: Text("Name")).onReceive(
        Just(newName)
      ) { newName in
        newNameValidated = newName != ""
      }

      TextField("Feed URL", text: $newURL, prompt: Text("Feed URL")).onReceive(
        Just(newURL)
      ) { newURL in
        guard let url = URL(string: newURL) else {
          newURLValidated = false
          return
        }

        let isHTTP = url.scheme?.hasPrefix("http") ?? false
        let isHTTPS = url.scheme?.hasPrefix("https") ?? false
        let hasDomain = url.host() != nil
        newURLValidated = (isHTTP || isHTTPS) && hasDomain
      }

      Button("OK") {
        withAnimation {
          let feed = Feed(name: newName, url: URL(string: newURL)!)
          var s = group.feeds.sorted(by: { $0.order < $1.order })
          s.append(feed)
          for (index, item) in s.enumerated() {
            item.order = index
          }
          group.feeds = s
          try? modelContext.save()
          Task {
            await fetchFeeds?(ignoreSchedule: false)
          }
        }
      }.keyboardShortcut(.defaultAction).disabled(
        !newNameValidated || !newURLValidated)
      Button("Cancel", role: .cancel) {
        // Do nothing
      }
    }
  }
}

struct FeedItemView: View {
  @State var feed: Feed

  @State private var shouldPresentSheet = false

  var body: some View {
    HStack {
      Favicon(
        url: feed.url
      )
      .frame(
        width: 24, height: 24)

      VStack(alignment: .leading) {
        Text(feed.name)
        Text(feed.url.absoluteString).font(.footnote)
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
          // Do noting
        } content: {
          FeedItemDetailsView(feed: feed)
        }
    }.padding(4)
  }
}

struct FeedGroupView: View {
  @State var group: FeedGroup

  @State private var presentDeleteAlert: Bool = false
  @State private var presentEditGroupNamePrompt: Bool = false
  @State private var shouldPresentSheet: Bool = false

  @State private var newGroupName: String = ""

  @Query(sort: \FeedGroup.order) var groups: [FeedGroup]

  @Environment(\.modelContext) var modelContext

  var body: some View {
    Section(group.name) {
      List {
        ForEach(group.feeds, id: \.id) { feed in
          FeedItemView(feed: feed)
        }.onMove { from, to in
          withAnimation {
            var s = group.feeds.sorted(by: { $0.order < $1.order })
            s.move(fromOffsets: from, toOffset: to)
            for (index, item) in s.enumerated() {
              item.order = index
            }
            group.feeds = s

            try? modelContext.save()
          }
        }

        if group.feeds.count == 0 {
          Text("No feeds. Click the context menu below to add one.")
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(10).font(.callout)
            .foregroundStyle(.secondary).frame(width: .infinity)
        }
      }

      HStack {
        Spacer()
        Menu {
          Button("Add feed") {
            shouldPresentSheet = true
          }
          if group.order > 0 {
            Button("Move up") {
              var s = groups.sorted(by: { $0.order < $1.order })
              s.move(
                fromOffsets: IndexSet(integer: group.order),
                toOffset: group.order - 1)
              for (index, item) in s.enumerated() {
                item.order = index
              }
              try? modelContext.save()
            }
          }
          if group.order < groups.count - 1 {
            Button("Move down") {
              var s = groups.sorted(by: { $0.order < $1.order })
              s.move(
                fromOffsets: IndexSet(integer: group.order),
                toOffset: group.order + 2)
              for (index, item) in s.enumerated() {
                item.order = index
              }
              try? modelContext.save()

            }
          }
          Button("Edit name") {
            presentEditGroupNamePrompt = true
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
            withAnimation {
              modelContext.delete(group)
              try? modelContext.save()
            }
          }.keyboardShortcut(.delete)
        } message: {
          Text(
            "The group will be removed, along with all of the feeds it contains."
          )
        }.dialogIcon(Image(systemName: "trash.circle.fill"))
        .alert(
          "Edit group name", isPresented: $presentEditGroupNamePrompt
        ) {
          TextField("Name", text: $newGroupName, prompt: Text(group.name))
          Button("OK") {
            withAnimation {
              group.name = newGroupName
              try? modelContext.save()

            }
          }.keyboardShortcut(.defaultAction)
          Button("Cancel", role: .cancel) {
            // Do nothing
          }
        }.dialogIcon(Image(systemName: "textformat.abc"))
        .alert("Test", isPresented: $shouldPresentSheet) {
          AddFeedAlertView(group: group)
        }.dialogIcon(Image(systemName: "plus.circle.fill"))
      }
    }

  }
}

struct FeedsSettingsView: View {
  @State private var filter: String = ""
  @FocusState var isFocused: Bool
  @State var presentPrompt: Bool = false
  @State var newName: String = ""

  @Environment(\.modelContext) var modelContext
  @Query(sort: \FeedGroup.order) var groups: [FeedGroup]
  @Query(sort: \Feed.name) var feeds: [Feed]

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
              // TODO
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
            Button("OK") {
              let group = FeedGroup(name: newName)
              group.order = groups.count
              modelContext.insert(group)
              try? modelContext.save()
            }.keyboardShortcut(.defaultAction)
            Button("Cancel", role: .cancel) {
              // Do nothing
            }

          } message: {
            Text("Select a name for the new group.")
          }.dialogIcon(Image(systemName: "textformat.abc"))

        }
      }

      ForEach(groups, id: \.id) { group in
        FeedGroupView(group: group)
      }
      if groups.count == 0 {
        Text("No feed groups. Click the plus button above to add one.")
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(10).font(.callout)
          .foregroundStyle(.secondary).frame(width: .infinity)
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
