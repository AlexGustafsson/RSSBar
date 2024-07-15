import Combine
import Foundation
import SwiftData
import SwiftUI
import os

private let logger = Logger(
  subsystem: Bundle.main.bundleIdentifier!, category: "UI/Settings")

struct FeedItemDetailsView: View {
  @State var feed: Feed

  @State private var newName = ""
  @State private var newURL = ""
  @State private var editing = false
  @State private var presentDeleteAlert = false
  @State private var newURLValidated = false

  @Environment(\.dismiss) var dismiss
  @Environment(\.updateIcon) var updateIcon
  @Environment(\.database) var database

  // Keep a query as the passed feed's items is not updated if they are changed,
  // for example when marking feed items as read
  @Query private var feedItems: [FeedItem]

  init(feed: Feed) {
    self.feed = feed
    print(feed.id)
    self._feedItems = Query(filter: #Predicate { $0.feed != nil } )
  }

  var body: some View {
    VStack(spacing: 0) {
      Form {
        Section {
          HStack {
            Favicon(url: feed.url, fallbackCharacter: feed.name)
              .frame(width: 48, height: 48)
            VStack(alignment: .leading) {
              if editing {
                TextField("Name", text: $newName, prompt: Text(feed.name))
                  .textFieldStyle(.plain).labelsHidden().font(.headline)
              } else {
                TruncatedText(feed.name).font(.headline)
              }
              Text(
                feed.lastUpdated == nil
                  ? "Never fetched"
                  : "Last fetched \(feed.lastUpdated!.formattedDistance(to: Date()))"
              )
              .font(.footnote).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
          }

          LabeledContent("Feed") {
            if editing {
              TextField(
                "Feed", text: $newURL, prompt: Text(feed.url.absoluteString)
              )
              .labelsHidden()
              .onChange(of: newURL) { _, newURL in
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
              TruncatedText(verbatim: feed.url.absoluteString)
            }
          }
          LabeledContent("Items") { Text("\(feedItems.count)") }
          LabeledContent("Unread items") { Text("\(feedItems.filter{$0.read == nil}.count)") }
        }

        Section("Actions") {
          List {
            Button("Mark all as read", role: .destructive) {
              Task {
                try? await database.markAllAsRead(feedId: feed.id)
                try? await database.save()
                // updateIcon?()
              }
            }
            Button("Clear history", role: .destructive) {
              Task {
                try? await database.clearHistory(feedId: feed.id)
                try? await database.save()
                // updateIcon?()
              }
            }
            Button("Clear items", role: .destructive) {
              Task {
                try? await database.clearItems(feedId: feed.id)
                try? await database.save()
                // updateIcon?()
              }
            }
            // TODO: Add a "Fetch now" button
          }
        }

        Section("Items") {
          List {
            ForEach(
              feedItems.sorted(by: {
                ($0.date ?? Date()) > ($1.date ?? Date())
              }), id: \.id
            ) { item in
              HStack(alignment: .center) {
                Favicon(url: item.url)
                  .frame(width: 24, height: 24)
                Text("\(item.feed!.id) \(feed.id)")
                VStack(alignment: .leading) {
                  TruncatedText(item.title).foregroundColor(.primary)
                  if item.date != nil {
                    Text(item.date!.formattedDistance(to: Date()))
                      .foregroundColor(.primary).font(.footnote)
                  }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                Button {
                  if item.url != nil {
                    NSWorkspace.shared.open(item.url!)
                    Task {
                      try? await database.markAsRead(feedItemId: item.id)
                      try? await database.save()
                      // updateIcon?()
                    }
                  }
                } label: {
                  Image(systemName: "rectangle.portrait.and.arrow.right")
                    .resizable().foregroundStyle(.secondary)
                    .frame(
                      width: 16, height: 16)
                }
                .buttonStyle(PlainButtonStyle())
              }
              .opacity(item.read == nil ? 1.0 : 0.6)
            }
            if feedItems.count == 0 {
              Text("No items").frame(maxWidth: .infinity, alignment: .center)
                .padding(10).font(.callout).foregroundStyle(.secondary)
                .frame(
                  width: .infinity)
            }
          }
        }
      }
      .padding(5).formStyle(.grouped)

      Divider()

      // Footer
      HStack {
        Button("Delete feed...") { presentDeleteAlert = true }
          .confirmationDialog(
            "Are you sure you want to delete this feed?",
            isPresented: $presentDeleteAlert
          ) {
            Button("Delete feed", role: .destructive) {
              Task {
                try? await database.deleteFeed(feedId: feed.id)
                try? await database.save()
                dismiss()
              }
            }
            .keyboardShortcut(.delete)
          } message: {
            Text(
              "The feed will be removed, along with the history of read entries."
            )
          }
          .dialogIcon(Image(systemName: "trash.circle.fill"))

        Spacer()
        Button(editing ? "Cancel" : "Edit") { editing = !editing }
          .keyboardShortcut(editing ? .cancelAction : nil)
        Button(editing ? "Save" : "Done") {
          if editing {
            if newName != "" { feed.name = newName }
            if newURL != "" { feed.url = URL(string: newURL)! }
            Task {
              try? await database.save()
              editing = !editing
            }
          } else {
            dismiss()
          }
        }
        .keyboardShortcut(.defaultAction)
        .disabled(
          editing && (newURL != "" && !newURLValidated))
      }
      .padding(20)
    }
  }
}
