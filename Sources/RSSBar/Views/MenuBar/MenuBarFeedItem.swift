import Foundation
import SwiftData
import SwiftUI
import os

private let logger = Logger(
  subsystem: Bundle.main.bundleIdentifier!, category: "UI/MenuBar")

struct MenuBarFeedItem: View {
  var feed: Feed

  @Environment(\.closeMenuBar) private var closeMenuBar
  @Environment(\.updateIcon) var updateIcon
  @Environment(\.modelContext) var modelContext

  @State private var isHovering = false
  @State private var showFeedItems = false

  var body: some View {
    Button(action: { showFeedItems = true }) {
      HStack(alignment: .center) {
        Favicon(url: feed.url, fallbackCharacter: feed.name)
          .frame(width: 24, height: 24)
        TruncatedText(feed.name).frame(maxWidth: .infinity, alignment: .leading)
          .padding(
            EdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
          )
          .foregroundColor(.primary)

        CountBadge(value: feed.unreadItemsCount)
      }
    }
    .buttonStyle(MenuBarItemButtonStyle(isHovering: isHovering))
    .onHover(
      perform: { flag in self.isHovering = flag })
      .popover(
        isPresented: $showFeedItems, arrowEdge: .trailing
      ) {
        VStack {
          if feed.items.count == 0 {
            Text("No items").frame(maxWidth: .infinity, alignment: .center)
              .padding(10).font(.callout).foregroundStyle(.secondary)
              .frame(
                width: .infinity)
          } else {
            List {
              ForEach(
                feed.items.sorted(by: {
                  ($0.date ?? Date()) > ($1.date ?? Date())
                }), id: \.id
              ) { item in
                MenuBarTextItem(
                  title: item.title,
                  subtitle: item.date?.formattedDistance(to: Date()),
                  systemName: "rectangle.portrait.and.arrow.right"
                ) {
                  showFeedItems = false
                  closeMenuBar()
                  if item.url != nil {
                    NSWorkspace.shared.open(item.url!)
                    try? modelContext.markAsRead(feedItemId: item.id)
                    try? modelContext.save()
                    updateIcon()
                  }
                }
                .opacity(item.read == nil ? 1.0 : 0.6)
                .listRowSeparator(.hidden)
              }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)

            Divider()
            MenuBarTextItem(title: "Mark all as read") {
              try? modelContext.markAllAsRead(feedId: feed.id)
              try? modelContext.save()
              showFeedItems = false
              updateIcon()
            }
          }
        }
        .frame(width: 250, height: 250)
        .padding(
          EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6))
      }
  }
}
