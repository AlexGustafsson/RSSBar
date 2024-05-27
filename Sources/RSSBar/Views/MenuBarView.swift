import Foundation
import SwiftUI

struct MyButtonStyle: ButtonStyle {
  var isHovering: Bool
  @State private var isPressed = false

  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
      .padding(EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6))
      .foregroundColor(.white)
      .background(
        self.isHovering ? .primary.opacity(0.1) : Color.clear
      )
      .cornerRadius(6)
  }

}

struct ListItem: View {
  @State private var isHovering = false
  @State private var favicon: URL?

  var body: some View {
    Button(action: {}) {
      HStack(alignment: .center) {
        AsyncImage(url: favicon) { image in
          image.resizable()
        } placeholder: {
          Image(systemName: "newspaper.circle.fill").resizable()
        }.frame(width: 24, height: 24)
        Text("GitHub.com").frame(maxWidth: .infinity, alignment: .leading)
          .padding(
            EdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
          ).foregroundColor(.primary)

        CountBadge(
          value: .constant(12)
        )
      }
    }
    .buttonStyle(
      MyButtonStyle(isHovering: isHovering)
    ).onHover(
      perform: { flag in
        self.isHovering = flag
      }).task {
        // TODO: Cache
        do {
          let urls = try await Favicon.identifyIcons(
            from: "https://github.com")
          print(urls)
          if let url = urls.first {
            favicon = try await Favicon.fetch(contentsOf: url)
          }
        } catch {
          // TODO: Log
          print("Failed to fetch favicon! \(error)")
        }
      }
  }
}

struct ListItemLite: View {
  var title: any StringProtocol
  var action: () -> Void
  @State private var isHovering = false

  var body: some View {
    Button(action: action) {
      Text(title).frame(maxWidth: .infinity, alignment: .leading)
        .padding(
          EdgeInsets(top: 1, leading: 2, bottom: 1, trailing: 2)
        ).foregroundColor(.primary)
    }
    .buttonStyle(
      MyButtonStyle(isHovering: isHovering)
    ).onHover(
      perform: { flag in
        self.isHovering = flag
      })
  }
}

struct MenuBarView: View {
  @Environment(\.openWindow) private var openWindow
  @Environment(\.closeMenuBar) private var closeMenuBar
  @Environment(\.quitApp) private var quitApp

  @State private var hoveredListItem: Int?

  var body: some View {
    VStack(alignment: .leading) {
      ListItemLite(
        title: "Fetch now",
        action: {
          // TODO
          closeMenuBar()
        })

      Divider()

      Text("News").fontWeight(.bold).frame(
        maxWidth: .infinity, alignment: .leading
      ).font(.subheadline).padding(
        EdgeInsets(top: 2, leading: 6, bottom: 0, trailing: 0)
      ).foregroundStyle(.secondary)
      LazyVStack(alignment: .leading, spacing: 0) {
        ListItem()
        ListItem()
        ListItem()
        ListItem()
      }

      Divider()

      Text("Tech").fontWeight(.bold).frame(
        maxWidth: .infinity, alignment: .leading
      ).font(.subheadline).padding(
        EdgeInsets(top: 2, leading: 6, bottom: 0, trailing: 0)
      ).foregroundStyle(
        .secondary
      )
      LazyVStack(alignment: .leading, spacing: 0) {
        ListItem()
        ListItem()
        ListItem()
        ListItem()
      }

      Divider()

      VStack(alignment: .leading, spacing: 0) {
        ListItemLite(
          title: "About",
          action: {
            openWindow(id: "about")
            closeMenuBar()
          })

        ListItemLite(
          title: "Settings",
          action: {
            openWindow(id: "settings")
            closeMenuBar()
          })

        ListItemLite(
          title: "Quit",
          action: {
            closeMenuBar()
            quitApp()
          })

      }
    }.padding(
      EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
    )
  }
}
