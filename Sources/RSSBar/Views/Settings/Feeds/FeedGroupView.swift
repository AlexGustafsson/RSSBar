import Combine
import Foundation
import SwiftData
import SwiftUI
import os

private let logger = Logger(
  subsystem: Bundle.main.bundleIdentifier!, category: "UI/FeedGroupView")

struct FeedGroupView: View {
  @State var group: FeedGroup
  @Binding var query: String

  @State private var presentDeleteAlert: Bool = false
  @State private var presentEditGroupNamePrompt: Bool = false
  @State private var shouldPresentSheet: Bool = false

  @State private var newGroupName: String = ""

  @Query(sort: \FeedGroup.order) var groups: [FeedGroup]

  @Environment(\.modelContext) private var modelContext

  var matchedFeeds: [Feed] {
    return self.group.feeds
      .filter {
        let title = $0.name.range(of: self.query, options: .caseInsensitive)
        let url = $0.url.absoluteString.range(
          of: query, options: .caseInsensitive)
        return query == "" || title != nil || url != nil
      }
      .sorted(by: { $0.order < $1.order })
  }

  var body: some View {
    Section(group.name) {
      List {
        ForEach(matchedFeeds, id: \.id) { feed in
          FeedView(feed: feed, query: $query)
            .draggable(feed.id)
        }
        // TODO: Only have onMove and onInsert when there is no search query,
        // otherwise the order is sort of messed up
        // If a search query has been specified, only a subset of items are
        // shown. If moving in such a scenario, move relative to the item
        .onMove { from, to in
          try? modelContext.moveFeedInGroup(
            groupId: group.id, from: from, to: to)
          try? modelContext.save()
        }
        .onInsert(
          of: [.persistentIdentifier],
          perform: { order, items in
            // If a search query has been specified, only a subset of items are
            // shown. If moving in such a scenario, move relative to the item
            // let resolvedOrder = matchedFeeds.firstIndex(where: {$0.order == order}) ?? (matchedFeeds.count - 1)

            // Store sendable primitives so we don't need to access self from
            // the completion handler's thread
            let groupId = group.id
            let modelContainer = modelContext.container
            for item in items {
              _ = item.loadTransferable(
                type: PersistentIdentifier.self,
                completionHandler: { result in
                  switch result {
                  case .success(let id):
                    // The completion handler is run in a different thread,
                    // create a new context
                    let modelContext = ModelContext(modelContainer)
                    try? modelContext.changeFeedGroup(
                      feedId: id, toGroup: groupId, at: order)
                    try? modelContext.save()
                  case .failure(let error):
                    logger.debug(
                      "Failed to perform drop \(error, privacy: .public)")
                  }
                })
            }
          })

        if group.feeds.count == 0 {
          Text("No feeds. Click the context menu below to add one.")
            .frame(
              maxWidth: .infinity, alignment: .center
            )
            .padding(10).font(.callout).foregroundStyle(.secondary)
        }
      }

      HStack {
        Spacer()
        Menu {
          Button("Add feed") { shouldPresentSheet = true }
          if group.order > 0 {
            Button("Move up") {
              try? modelContext.moveGroup(groupId: group.id, positions: -1)
              try? modelContext.save()
            }
          }
          if group.order < groups.count - 1 {
            Button("Move down") {
              try? modelContext.moveGroup(groupId: group.id, positions: +2)
              try? modelContext.save()
            }
          }
          Button("Edit name") { presentEditGroupNamePrompt = true }
          Button("Delete...", role: .destructive) { presentDeleteAlert = true }
        } label: {
          Image(systemName: "ellipsis")
        }
        .fixedSize()
        .confirmationDialog(
          "Are you sure you want to delete this group?",
          isPresented: $presentDeleteAlert
        ) {
          Button("Delete group", role: .destructive) {
            modelContext.delete(group)
            try? modelContext.save()
          }
          .keyboardShortcut(.delete)
        } message: {
          Text(
            "The group will be removed, along with all of the feeds it contains."
          )
        }
        .dialogIcon(Image(systemName: "trash.circle.fill"))
        .alert(
          "Edit group name", isPresented: $presentEditGroupNamePrompt
        ) {
          TextField("Name", text: $newGroupName, prompt: Text(group.name))
          Button("OK") {
            group.name = newGroupName
            try? modelContext.save()
          }
          .keyboardShortcut(.defaultAction)
          Button("Cancel", role: .cancel) {
            // Do nothing
          }
        }
        .dialogIcon(Image(systemName: "textformat.abc"))
        .sheet(isPresented: $shouldPresentSheet) {
          AddFeedView(group: group)
        }
      }
    }
    .dropDestination(for: PersistentIdentifier.self) { items, location in
      print(items)
      return true
    }

  }
}
