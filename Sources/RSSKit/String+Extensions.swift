extension String {
  func cut(at separator: any StringProtocol) -> (
    String.SubSequence, String.SubSequence
  )? {
    guard let range = self.range(of: separator) else {
      return nil
    }

    return (
      self.prefix(upTo: range.lowerBound),
      self.suffix(from: range.upperBound)
    )
  }
}
