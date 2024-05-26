import Foundation

extension Date {
  init?(fromRFC3339 value: String) {
    let formatter = ISO8601DateFormatter()
    if let date = formatter.date(from: value) {
      self.init(timeInterval: 0, since: date)
    } else {
      return nil
    }
  }

  init?(fromRFC2822 value: String) {
    let formatter = DateFormatter()
    // Fri, 21 Jul 2023 09:04 EDT
    // or
    // Fri, 21 Jul 2023 09:04:03 EDT
    if value.count == 26 {
      formatter.dateFormat = "E, d LLL y H:m z"
    } else {
      formatter.dateFormat = "E, d LLL y H:m:s z"
    }
    formatter.locale =
      NSLocale(localeIdentifier: "en_US_POSIX") as Locale
    if let date = formatter.date(from: value) {
      self.init(timeInterval: 0, since: date)
    } else {
      return nil
    }
  }
}
