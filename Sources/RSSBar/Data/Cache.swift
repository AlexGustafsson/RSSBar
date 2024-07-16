import Foundation
import SwiftUI

protocol Cache<Key, Value> {
  associatedtype Key: Hashable
  associatedtype Value

  func insert(_ value: Value, forKey key: Key) throws

  func value(forKey key: Key) throws -> Value?

  func remove(forKey key: Key) throws
}

final class DiskCache: Cache, Sendable {
  typealias Key = String
  typealias Value = Data

  private let root: URL

  static let shared = try! DiskCache()

  init(at root: URL) throws {
    self.root = root.appending(
      components: "cache", "v1", directoryHint: .isDirectory)

    try FileManager.default.createDirectory(
      at: self.root, withIntermediateDirectories: true, attributes: nil)
  }

  convenience init() throws {
    // The bundle identifier is always included on build - crash if it's not
    let bundleID = Bundle.main.bundleIdentifier!
    let applicationSupport = try FileManager.default.url(
      for: .applicationSupportDirectory, in: .userDomainMask,
      appropriateFor: nil, create: false)

    let appSupportSubDirectory = applicationSupport.appending(
      path: bundleID, directoryHint: .isDirectory)

    try self.init(at: appSupportSubDirectory)
  }

  func insert(_ value: Data, forKey key: String) throws {
    try value.write(to: self.root.appending(component: key), options: .atomic)
  }

  func url(forKey key: String) -> URL {
    return self.root.appending(component: key)
  }

  func urlIfExists(forKey key: String) -> URL? {
    let url = self.url(forKey: key)
    if FileManager.default.fileExists(atPath: url.path) {
      return url
    } else {
      return nil
    }
  }

  func value(forKey key: String) throws -> Data? {
    let url = self.url(forKey: key)
    if FileManager.default.fileExists(atPath: url.path) {
      return try Data(contentsOf: self.url(forKey: key))
    } else {
      return nil
    }
  }

  func remove(forKey key: String) throws {
    try FileManager.default.removeItem(at: self.url(forKey: key))
  }

  func removeAll() throws { try FileManager.default.removeItem(at: self.root) }
}
