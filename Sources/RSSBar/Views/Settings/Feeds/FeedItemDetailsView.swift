import Combine
import Foundation
import SwiftData
import SwiftUI
import os

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
            Favicon(url: feed.url, fallbackCharacter: feed.name)
              .frame(width: 48, height: 48)
            VStack(alignment: .leading) {
              if editing {
                TextField("Name", text: $newName, prompt: Text(feed.name))
                  .textFieldStyle(.plain).labelsHidden().font(.headline)
              } else {
                Text(feed.name).font(.headline)
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
              Text(verbatim: feed.url.absoluteString)
            }
          }
          LabeledContent("Items") { Text("\(feed.items.count)") }
          LabeledContent("Unread items") { Text("\(feed.unreadItemsCount)") }
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
              LabeledContent("Update interval") { Text("Default") }
            }
          }
        }

        Section("Actions") {
          List {
            Button("Clear history", role: .destructive) {
              for item in feed.items { item.read = nil }
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
                Favicon(url: item.url)
                  .frame(width: 24, height: 24)
                VStack(alignment: .leading) {
                  Text(item.title).foregroundColor(.primary)
                  Text(item.date?.formattedDistance(to: Date()) ?? "")
                    .foregroundColor(.primary).font(.footnote)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                Button {
                  if item.url != nil {
                    NSWorkspace.shared.open(item.url!)
                    item.read = Date()
                    try? modelContext.save()
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
            if feed.items.count == 0 {
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
              withAnimation {
                let group = feed.group!
                var s = group.feeds.sorted(by: { $0.order < $1.order })
                s.remove(at: feed.order)
                for (index, item) in s.enumerated() { item.order = index }
                group.feeds = s

                try? modelContext.save()

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
            withAnimation {
              if newName != "" { feed.name = newName }
              if newURL != "" { feed.url = URL(string: newURL)! }
              // TODO: Update interval
              try? modelContext.save()
            }
            editing = !editing
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
