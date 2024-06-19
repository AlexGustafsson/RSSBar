import Foundation
import SwiftData
import SwiftUI

struct MenuBarTextItem: View {
  var title: any StringProtocol
  var subtitle: (any StringProtocol)?
  var systemName: String?

  var action: () -> Void

  var body: some View {
    MenuBarItem {
      action()
    } label: {
      HStack {
        VStack(alignment: .leading) {
          TruncatedText(title).foregroundColor(.primary)
          if subtitle != nil {
            TruncatedText(subtitle!).font(.footnote).foregroundColor(.primary)
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
