import Foundation
import XCTest

@testable import RSSKit

final class RSSKitTests: XCTestCase {
  // func testFetch() async throws {
  //   let x = RSSFeed(
  //     url: URL(string: "https://github.com/traefik/traefik/releases.atom")!)
  //   try await x.fetch()
  // }

  func testParseRSS() {
    let input = """
      <?xml version="1.0" encoding="utf-8"?>
       <feed xmlns="http://www.w3.org/2005/Atom"
        xmlns:fh="http://purl.org/syndication/history/1.0">
        <title>NetMovies Queue</title>
        <subtitle>The DVDs you'll receive next.</subtitle>
        <link href="http://example.org/"/>
        <fh:complete/>
        <link rel="self"
         href="http://netmovies.example.org/jdoe/queue/index.atom"/>
        <updated>2003-12-13T18:30:02Z</updated>
        <author>
          <name>John Doe</name>
        </author>
        <id>urn:uuid:60a76c80-d399-11d9-b93C-0003939e0af6</id>
        <entry>
          <title>Casablanca</title>
          <link href="http://netmovies.example.org/movies/Casablanca"/>
          <id>urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a</id>
          <updated>2003-12-13T18:30:02Z</updated>
          <summary>Here's looking at you, kid...</summary>
        </entry>
       </feed>
      """
    let x = parseRSS(data: Data(input.utf8))
    print("Res: \(x!.description)")
  }
}
