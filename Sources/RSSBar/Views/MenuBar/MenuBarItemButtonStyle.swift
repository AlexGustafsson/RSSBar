import Foundation
import SwiftData
import SwiftUI

struct MenuBarItemButtonStyle: ButtonStyle {
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
