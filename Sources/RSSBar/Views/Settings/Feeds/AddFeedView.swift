import Combine
import Foundation
import SwiftData
import SwiftUI
import os

struct AddFeedView: View {
  @State var group: FeedGroup

  @State private var newName: String = ""
  @State private var newNameValidated = false
  @State private var newURL: URL?
  @State private var newURLString: String = ""
  @State private var newURLValidated = false

  @State private var newRepositoryOwner = ""
  @State private var newRepositoryName = ""

  @Environment(\.modelContext) var modelContext
  @Environment(\.dismiss) var dismiss
  @Environment(\.fetchFeeds) var fetchFeeds

  enum FeedType: String, CaseIterable, Identifiable {
    case url, github

    var id: Self { self }

    var description: String {
      switch self {
      case .url:
        return "Feed"
      case .github:
        return "GitHub Release"
      }
    }
  }

  @State private var selectedFeedType: FeedType = .url

  var body: some View {
    VStack(spacing: 0) {
      Form {
        Section {
          HStack {
            Favicon(
              url: newURL,
              fallbackCharacter: newName,
              fallbackSystemName: "list.bullet"
            )
            .frame(width: 48, height: 48)
            VStack(alignment: .leading) {
              TextField("Name", text: $newName, prompt: Text("Name"))
                .textFieldStyle(.plain).labelsHidden().font(.headline)
                .font(.footnote).foregroundStyle(.secondary)
                .onReceive(
                  Just(newName)
                ) { newName in newNameValidated = newName != "" }

            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
          }
        } header: {
          Menu {
            Button("URL") {
              // TODO: Add support for discoverying feed from linl
              // <link rel="alternate" type="application/rss+xml" href="xxx">
              selectedFeedType = .url
            }
            Section("GitHub") {
              Button("Releases") {
                selectedFeedType = .github
              }
              Button("Tags") {
              }
              Button("Commits") {
              }
              Button("User") {
              }
            }
            Section("Social") {
              Button("Mastodon user") {
              }
              Button("Bluesky profile") {
                // https://bsky.app/profile/molly.wiki + alternate link
              }
            }
            Section("Redit") {
              Button("Homepage") {
                // "http://www.reddit.com/.rss"
              }
              Button("Subreddit") {
                // "https://old.reddit.com/r/rss/hot/.rss"
              }
              Button("User") {
                // http://old.reddit.com/user/alienth/.rss,
              }
              Button("Domain") {
                // https://old.reddit.com/domain/imgur.com/.rss
              }
            }
            Section("Proxy") {
              Button("Open RSS") {
                // 404: https://openrss.org/www.doesnoteexist.com
                // rss: https://openrss.org/www.starwars.com
              }
            }
          } label: {
            Text("Add \(selectedFeedType.description)").font(.headline)
          }
          .menuStyle(.borderlessButton)
        }

        switch selectedFeedType {
        case .url:
          Section {
            TextField(
              "Feed", text: $newURLString,
              prompt: Text("https://example.com/feed.atom")
            )
            .onReceive(
              Just(newURLString)
            ) { newURLString in
              guard let url = URL(string: newURLString) else {
                newURLValidated = false
                return
              }

              let isHTTP = url.scheme?.hasPrefix("http") ?? false
              let isHTTPS = url.scheme?.hasPrefix("https") ?? false
              let hasDomain = url.host() != nil
              newURLValidated = (isHTTP || isHTTPS) && hasDomain
              if newURLValidated {
                newURL = url
              }
            }
          }
        case .github:
          Section {
            TextField(
              "Repository owner", text: $newRepositoryOwner,
              prompt: Text("owner")
            )
            .onReceive(
              Just(newRepositoryOwner)
            ) { newRepositoryOwner in
              guard
                let url = URL(
                  string:
                    "https://github.com/\(newRepositoryOwner)/\(newRepositoryName)"
                )
              else {
                newURLValidated = false
                return
              }

              let isHTTP = url.scheme?.hasPrefix("http") ?? false
              let isHTTPS = url.scheme?.hasPrefix("https") ?? false
              let hasDomain = url.host() != nil
              newURLValidated = (isHTTP || isHTTPS) && hasDomain
              if newURLValidated {
                newURL = url
              }
            }

            TextField(
              "Repository name", text: $newRepositoryName,
              prompt: Text("name")
            )
            .onReceive(
              Just(newRepositoryOwner)
            ) { newRepositoryOwner in
              guard
                let url = URL(
                  string:
                    "https://github.com/\(newRepositoryOwner)/\(newRepositoryName)"
                )
              else {
                newURLValidated = false
                return
              }

              let isHTTP = url.scheme?.hasPrefix("http") ?? false
              let isHTTPS = url.scheme?.hasPrefix("https") ?? false
              let hasDomain = url.host() != nil
              newURLValidated = (isHTTP || isHTTPS) && hasDomain
              if newURLValidated {
                newURL = url
              }
            }
          }
        }
      }
      .padding(5).formStyle(.grouped)

      Divider()

      // Footer
      HStack {
        Spacer()
        Button(
          "Cancel"
        ) {
          dismiss()
        }
        .keyboardShortcut(.cancelAction)
        Button("Add") {
          withAnimation {
            let feed = Feed(name: newName, url: newURL!)
            var s = group.feeds.sorted(by: { $0.order < $1.order })
            s.append(feed)
            for (index, item) in s.enumerated() { item.order = index }
            group.feeds = s
            try? modelContext.save()
            dismiss()
            Task { await fetchFeeds?(ignoreSchedule: false) }
          }
        }
        .keyboardShortcut(.defaultAction)
        .disabled(!newNameValidated || !newURLValidated)
      }
      .padding(20)
    }
    .frame(width: 420, height: 420)
  }
}
