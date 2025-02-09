import Foundation

extension UserDefaults {

  enum Keys: String, CaseIterable {
    case enableFaviconsFetching
  }

  func reset() {
    for key in Keys.allCases {
      removeObject(forKey: key.rawValue)
    }
  }
}
