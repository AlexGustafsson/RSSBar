import Combine
import Foundation
import SwiftData
import SwiftUI
import os

struct FeedItemView: View {
  @State var feed: Feed
  @Binding var query: String

  @State private var shouldPresentSheet = false

  var body: some View {
    HStack {
      Favicon(url: feed.url, fallbackCharacter: feed.name)
        .frame(width: 24, height: 24)

      VStack(alignment: .leading) {
        Text(feed.name) { string in
          if query != "" {
            string.foregroundColor = .secondary
            if let range = string.range(of: query, options: .caseInsensitive) {
              string[range].foregroundColor = .primary
            }
          }
        }

        Text(feed.url.absoluteString) { string in
          if query != "" {
            string.foregroundColor = .secondary
            if let range = string.range(of: query, options: .caseInsensitive) {
              string[range].foregroundColor = .primary
            }
          }
        }
        .font(.footnote)
        .foregroundStyle(
          .secondary)
      }
      .frame(maxWidth: .infinity, alignment: .topLeading)

      Button {
        shouldPresentSheet.toggle()
      } label: {
        Image(systemName: "info.circle").resizable().foregroundStyle(.secondary)
          .frame(width: 16, height: 16)
      }
      .buttonStyle(PlainButtonStyle())
      .sheet(isPresented: $shouldPresentSheet) {
        // Do noting
      } content: {
        FeedItemDetailsView(feed: feed)
      }
    }
    .padding(4)
  }
}
