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
          Text(
            title.trimmingCharacters(in: .whitespacesAndNewlines)
          )
          .help(Text(title.trimmingCharacters(in: .whitespacesAndNewlines)))
          .foregroundColor(.primary).lineLimit(1)
          .truncationMode(.tail)
          if subtitle != nil {
            Text(
              subtitle!.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            .font(.footnote).foregroundColor(.primary)
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
