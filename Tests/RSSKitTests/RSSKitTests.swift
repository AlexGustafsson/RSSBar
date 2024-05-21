import Foundation
import XCTest

@testable import RSSKit

final class RSSKitTests: XCTestCase {
  func testFetch() async throws {
    let x = RSSFeed(
      url: URL(string: "https://github.com/traefik/traefik/releases.atom")!)
    try await x.fetch()
  }
}
