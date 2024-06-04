import Foundation

extension Date {
  func formattedDistance(to other: Date) -> String {
    var diff = self.distance(to: other)

    let prefix = diff > 0 ? "in " : ""
    let postfix = diff <= 0 ? " ago" : ""

    diff = floor(abs(diff))

    let seconds = diff
    if seconds < 60 {
      return "\(prefix)\(seconds)s\(postfix)"
    }

    let minutes = floor(seconds / 60)
    if minutes < 60 {
      return "\(prefix)\(minutes)m\(postfix)"
    }

    let hours = floor(minutes / 60)
    if hours < 60 {
      return "\(prefix)\(hours)h\(postfix)"
    }

    let days = floor(hours / 24)
    if days < 24 {
      return "\(prefix)\(days)d\(postfix)"
    }

    let years = floor(days / 365)
    return "\(prefix)\(years)y\(postfix)"
  }
}