import SwiftUI

extension View {
  @ViewBuilder func help(_ text: Text, show: Bool) -> some View {
    if show {
      self.help(text)
    }

    self
  }
}

struct TruncatedText: View {
  var content: (any StringProtocol)?
  var attributedContent: AttributedString?

  private enum Mode {
    case `default`
    case verbatim
    case attributed
  }
  private var mode: Mode

  @State private var truncatedSize: CGSize = .zero
  @State private var intrinsicSize: CGSize = .zero

  init(_ text: any StringProtocol) {
    self.content = text.trimmingCharacters(in: .whitespacesAndNewlines)
    self.mode = .default
  }

  init(verbatim text: any StringProtocol) {
    self.content = text.trimmingCharacters(in: .whitespacesAndNewlines)
    self.mode = .verbatim
  }

  init(_ attributedContent: AttributedString) {
    self.attributedContent = attributedContent
    self.mode = .attributed
  }

  // TODO: Never results in re-render...
  private var isTruncated: Bool {
    truncatedSize.width < intrinsicSize.width
  }

  var text: some View {
    switch mode {
    case .default:
      Text(content!)
        .help(Text(content!), show: isTruncated)
    case .verbatim:
      Text(verbatim: String(content!))
        .help(Text(content!), show: isTruncated)

    case .attributed:
      Text(attributedContent!)
        .help(
          Text(attributedContent!), show: isTruncated)
    }
  }

  var body: some View {
    text
      .lineLimit(1)
      .truncationMode(.tail)
      .readSize { size in
        truncatedSize = size
      }
      .background(
        text.hidden()
          .fixedSize(horizontal: false, vertical: true)
          .readSize { size in
            intrinsicSize = size
          })
  }
}
