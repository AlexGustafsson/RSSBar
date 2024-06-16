import Foundation
import SwiftUI

private struct MenuBarItemButtonStyle: ButtonStyle {
  var isHovering: Bool = false
  @State private var isPressed = false

  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
      .padding(
        EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6)
      )
      .foregroundColor(.white)
      .background(
        self.isHovering ? .primary.opacity(0.1) : Color.clear
      )
      .cornerRadius(6)
  }
}

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
        Text(feed.name).frame(maxWidth: .infinity, alignment: .leading)
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
                action: {
                  showFeedItems = false
                  closeMenuBar()
                  if item.url != nil {
                    NSWorkspace.shared.open(item.url!)
                    item.read = Date()
                    try? modelContext.save()
                  }
                }, title: item.title,
                subtitle: item.date?.formattedDistance(to: Date()) ?? "",
                systemName: "rectangle.portrait.and.arrow.right"
              )
              .opacity(item.read == nil ? 1.0 : 0.6)
            }
          }
          Divider()
          MenuBarTextItem(
            action: {
              for item in feed.items {
                if item.read == nil { item.read = Date() }
              }
              try? modelContext.save()
              showFeedItems = false
            }, title: "Mark all as read")
        }
        .frame(width: 250, height: 250)
        .padding(
          EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6))
      }
  }
}

struct MenuBarTextItem: View {
  var action: () -> Void
  var title: any StringProtocol
  var subtitle: (any StringProtocol)?
  var systemName: String?

  var body: some View {
    MenuBarItem {
      action()
    } label: {
      HStack {
        VStack(alignment: .leading) {
          Text(title).foregroundColor(.primary).lineLimit(1)
            .truncationMode(.tail)
          if subtitle != nil {
            Text(subtitle!).font(.footnote).foregroundColor(.primary)
              .lineLimit(1).truncationMode(.tail)
          }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        if systemName != nil {
          Image(systemName: systemName!).foregroundColor(.primary)
        }
      }
    }
  }
}

struct MenuBarItem<Label>: View where Label: View {
  var action: () -> Void
  var label: () -> Label
  @State private var isHovering = false

  var body: some View {
    Button(action: action, label: label)
      .buttonStyle(
        MenuBarItemButtonStyle(isHovering: isHovering)
      )
      .onHover(perform: { flag in self.isHovering = flag })
  }
}
