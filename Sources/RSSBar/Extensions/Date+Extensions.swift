import Foundation

extension Date {
  func formattedDistance(to other: Date) -> String {
    var diff = self.distance(to: other)

    let prefix = diff < 0 ? "in " : ""
    let postfix = diff >= 0 ? " ago" : ""

    diff = floor(abs(diff))

    let seconds = diff
    if seconds == 0 { return "just now" }
    if seconds < 60 {
      return
        "\(prefix)\(Int(seconds)) second\(seconds > 1 ? "s" : "")\(postfix)"
    }

    let minutes = floor(seconds / 60)
    if minutes < 60 {
      return
        "\(prefix)\(Int(minutes)) minute\(minutes > 1 ? "s" : "")\(postfix)"
    }

    let hours = floor(minutes / 60)
    if hours < 60 {
      return "\(prefix)\(Int(hours)) hour\(hours > 1 ? "s" : "")\(postfix)"
    }

    let days = floor(hours / 24)
    if days < 30 {
      return "\(prefix)\(Int(days)) day\(days > 1 ? "s" : "")\(postfix)"
    }

    let months = floor(days / 30)
    if days < 365 {
      return "\(prefix)\(Int(months)) month\(months > 1 ? "s" : "")\(postfix)"
    }

    let years = floor(days / 365)
    return "\(prefix)\(Int(years)) year\(years > 1 ? "s" : "")\(postfix)"
  }
}
