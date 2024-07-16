import Combine
import Foundation
import SwiftData
import SwiftUI
import os

struct FeedsSettingsView: View {
  @State var presentPrompt: Bool = false
  @State var newName: String = ""
  @State var query: String = ""

  @Environment(\.modelContext) var modelContext
  @Query(sort: \FeedGroup.order) var groups: [FeedGroup]
  @Query(sort: \Feed.name) var feeds: [Feed]

  var body: some View {
    Form {
      // Topbar
      Section {
        HStack {
          // Search Bar
          HStack {
            Image(systemName: "magnifyingglass")
            TextField("Search", text: $query, prompt: Text("Search"))
              .labelsHidden().disableAutocorrection(true)
          }

          // Add button
          Menu {
            Button("New group") { presentPrompt = true }
          } label: {
            Image(systemName: "plus")
          }
          .fixedSize()
          .alert("Add new group", isPresented: $presentPrompt) {
            TextField("Name", text: $newName, prompt: Text("Group name"))
            Button("OK") {
              try? modelContext.addGroup(name: newName)
              try? modelContext.save()
            }
            .keyboardShortcut(.defaultAction)
            Button("Cancel", role: .cancel) {
              // Do nothing
            }
          } message: {
            Text("Select a name for the new group.")
          }
          .dialogIcon(Image(systemName: "textformat.abc"))

        }
      }

      // Feed groups
      ForEach(groups, id: \.persistentModelID) { group in
        FeedGroupView(group: group, query: $query)
      }
      // ... or placeholder
      if groups.count == 0 {
        Text("No feed groups. Click the plus button above to add one.")
          .frame(
            maxWidth: .infinity, alignment: .center
          )
          .padding(10).font(.callout).foregroundStyle(.secondary)
          .frame(
            width: .infinity)
      }
    }
    .formStyle(.grouped)
  }
}
