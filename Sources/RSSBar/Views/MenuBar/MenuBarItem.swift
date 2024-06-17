import Foundation
import SwiftData
import SwiftUI

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
