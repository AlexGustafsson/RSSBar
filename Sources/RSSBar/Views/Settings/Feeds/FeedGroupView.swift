import Combine
import Foundation
import SwiftData
import SwiftUI
import os

struct FeedGroupView: View {
  @State var group: FeedGroup
  @Binding var query: String

  @State private var presentDeleteAlert: Bool = false
  @State private var presentEditGroupNamePrompt: Bool = false
  @State private var shouldPresentSheet: Bool = false

  @State private var newGroupName: String = ""

  @Query(sort: \FeedGroup.order) var groups: [FeedGroup]

  @Environment(\.modelContext) var modelContext

  var matchedFeeds: [Feed] {
    return self.group.feeds.sorted(by: { $0.order < $1.order })
      .filter {
        let title = $0.name.range(of: self.query, options: .caseInsensitive)
        let url = $0.url.absoluteString.range(
          of: query, options: .caseInsensitive)
        return query == "" || title != nil || url != nil
      }
  }

  var body: some View {
    Section(group.name) {
      List {
        ForEach(matchedFeeds, id: \.id) { feed in
          FeedItemView(feed: feed, query: $query)
        }
        .onMove { from, to in
          withAnimation {
            var s = group.feeds.sorted(by: { $0.order < $1.order })
            s.move(fromOffsets: from, toOffset: to)
            for (index, item) in s.enumerated() { item.order = index }
            group.feeds = s

            try? modelContext.save()
          }
        }

        if group.feeds.count == 0 {
          Text("No feeds. Click the context menu below to add one.")
            .frame(
              maxWidth: .infinity, alignment: .center
            )
            .padding(10).font(.callout).foregroundStyle(.secondary)
            .frame(
              width: .infinity)
        }
      }

      HStack {
        Spacer()
        Menu {
          Button("Add feed") { shouldPresentSheet = true }
          if group.order > 0 {
            Button("Move up") {
              var s = groups.sorted(by: { $0.order < $1.order })
              s.move(
                fromOffsets: IndexSet(integer: group.order),
                toOffset: group.order - 1)
              for (index, item) in s.enumerated() { item.order = index }
              try? modelContext.save()
            }
          }
          if group.order < groups.count - 1 {
            Button("Move down") {
              var s = groups.sorted(by: { $0.order < $1.order })
              s.move(
                fromOffsets: IndexSet(integer: group.order),
                toOffset: group.order + 2)
              for (index, item) in s.enumerated() { item.order = index }
              try? modelContext.save()

            }
          }
          Button("Edit name") { presentEditGroupNamePrompt = true }
          Button("Delete", role: .destructive) { presentDeleteAlert = true }
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
            withAnimation {
              group.name = newGroupName
              try? modelContext.save()

            }
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

  }
}
