import SwiftUI

struct MenuBarSectionHeader: View {
  var text: String

  init(_ text: String) {
    self.text = text
  }

  var body: some View {
    TruncatedText(self.text).fontWeight(.bold)
      .frame(
        maxWidth: .infinity, alignment: .leading
      )
      .font(.subheadline)
      .padding(
        EdgeInsets(top: 2, leading: 6, bottom: 0, trailing: 0)
      )
      .foregroundStyle(.secondary)
  }
}
