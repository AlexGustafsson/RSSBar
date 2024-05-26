import Foundation
import SwiftUI

struct MenuBarView: View {
  @Environment(\.openWindow) private var openWindow
  @Environment(\.closeMenuBar) private var closeMenuBar

  var body: some View {
    VStack(alignment: .center) {
      Button("Open about") {
        openWindow(id: "about")
        closeMenuBar()
      }.onHover { inside in
        if inside {
          NSCursor.pointingHand.push()
        } else {
          NSCursor.pop()
        }
      }

    }
    .padding()
  }
}
