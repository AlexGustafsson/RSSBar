import Foundation
import SwiftUI

struct Tree: Identifiable, Hashable {
  let id = UUID()
  var name: String
  var level: Int = 0
  var children: [Tree]? = nil
}

struct AddFeedFormView: View {
  @State private var url: String = ""
  @State private var name: String = ""

  var body: some View {
    Form {
      Section {
        // TODO: Read favicon / image as soon as we have a URL
        Image(systemName: "network").resizable()
          .scaledToFit()
          .frame(width: 128.0, height: 128.0)
        TextField("Feed URL", text: $url).textContentType(.URL)
          .disableAutocorrection(true)
        TextField("Display name", text: $name)
      }
      Section {
        Button("Check now", action: {})
      }
    }.formStyle(.columns).frame(maxWidth: 400)
  }
}

struct SettingsView: View {
  let trees = [
    Tree(
      name: "News",
      children: [
        Tree(name: "news.ycombinator.com", level: 1),
        Tree(name: "One-2", level: 1),
        Tree(name: "One-3", level: 1),
      ]),
    Tree(
      name: "GitHub relases",
      children: [
        Tree(name: "Quickterm", level: 1),
        Tree(name: "RSSBar", level: 1),
        Tree(name: "homebridge-wol", level: 1),
        Tree(name: "threes", level: 1),
      ]),
    Tree(name: "Empty"),
  ]

  @State private var selection: Tree?

  var body: some View {

    NavigationSplitView {
      List(selection: $selection) {
        Section("Feeds") {
          OutlineGroup(trees, id: \.id, children: \.children) { tree in
            NavigationLink(
              tree.name, value: tree
            ).contextMenu(menuItems: {
              Button("Add feed") {

              }
              Button("Delete collection") {

              }

            })
            // Doesn't work to have navigation in hstack - selected item not
            // updated. So we can't have icons in them?
            // HStack(alignment: .center) {
            // Spacer()
            // Image(systemName: "minus.circle")
            //   .onTapGesture {
            //   }
            // if tree.level == 0 {
            //   Image(systemName: "plus.circle")
            //     .onTapGesture {
            //     }
            // }
          }
        }
      }.listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
          VStack(spacing: 0) {
            Divider()
            HStack {
              Button(
                "New group",
                systemImage: "plus.circle",
                action: {

                }
              ).buttonStyle(PlainButtonStyle())
              Spacer()
            }
            .padding(8)
          }
        }
    } detail: {
      if let tree = selection {
        Text("Tree element \(tree.name)")
          .navigationTitle(tree.name)
      } else {
        AddFeedFormView()
      }
    }.navigationSplitViewStyle(.balanced).toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button(action: {
          // Action to perform
        }) {
          // Custom view for the button
          Text("Add feed")
        }

      }
    }

  }

}
