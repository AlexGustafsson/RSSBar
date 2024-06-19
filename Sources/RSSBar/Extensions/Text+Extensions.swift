import SwiftUI

/// Extension to make applying AttributedString even easier
extension Text {
  init(
    _ content: any StringProtocol, attribute: ((inout AttributedString) -> Void)
  ) {
    var attributedContent = AttributedString(content)
    attribute(&attributedContent)
    self.init(attributedContent)
  }
}

/// Extension to make applying AttributedString even easier
extension TruncatedText {
  init(_ content: String, attribute: ((inout AttributedString) -> Void)) {
    var attributedContent = AttributedString(content)
    attribute(&attributedContent)
    self.init(attributedContent)
  }
}
