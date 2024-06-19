import Foundation
import SwiftData
import SwiftUI
import os

private let logger = Logger(
  subsystem: Bundle.main.bundleIdentifier!, category: "UI/MenuBar")

struct MenuBarFeedItem: View {
  var feed: Feed

  @Environment(\.closeMenuBar) private var closeMenuBar
  @Environment(\.modelContext) var modelContext

  @State private var isHovering = false
  @State private var showFeedItems = false

  var body: some View {
    Button(action: { if feed.items.count > 0 { showFeedItems = true } }) {
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
                  item.read = Date()
                  try? modelContext.save()
                }
              }
              .opacity(item.read == nil ? 1.0 : 0.6)
            }
          }
          .listStyle(.plain)

          Divider()
          MenuBarTextItem(title: "Mark all as read") {
            for item in feed.items {
              item.read = item.read ?? Date()
            }
            do {
              try modelContext.save()
            } catch {
              logger.error("Failed to mark all items as read \(error)")
            }
            showFeedItems = false
          }
        }
        .frame(width: 250, height: 250)
        .padding(
          EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6))
      }
  }
}
