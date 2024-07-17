import Foundation

extension UserDefaults {

    enum Keys: String, CaseIterable {
        case enableFaviconsFetching
    }

    func reset() {
        Keys.allCases.forEach { removeObject(forKey: $0.rawValue) }
    }
}
