import CustomDump
import Foundation
import XCTest

@testable import RSSKit

final class RSSTests: XCTestCase {
  func testParseAtom() throws {
    // SEE: https://datatracker.ietf.org/doc/html/rfc4287
    let input = """
      <?xml version="1.0" encoding="utf-8"?>
      <feed xmlns="http://www.w3.org/2005/Atom">
        <title type="text">dive into mark</title>
        <subtitle type="html">
          A &lt;em&gt;lot&lt;/em&gt; of effort
          went into making this effortless
        </subtitle>
        <updated>2005-07-31T12:29:29Z</updated>
        <id>tag:example.org,2003:3</id>
        <link rel="alternate" type="text/html"
          hreflang="en" href="http://example.org/"/>
        <link rel="self" type="application/atom+xml"
          href="http://example.org/feed.atom"/>
        <rights>Copyright (c) 2003, Mark Pilgrim</rights>
        <generator uri="http://www.example.com/" version="1.0">
          Example Toolkit
        </generator>
        <entry>
          <title>Atom draft-07 snapshot</title>
          <link rel="alternate" type="text/html"
            href="http://example.org/2005/04/02/atom"/>
          <link rel="enclosure" type="audio/mpeg" length="1337"
            href="http://example.org/audio/ph34r_my_podcast.mp3"/>
          <id>tag:example.org,2003:3.2397</id>
          <updated>2005-07-31T12:29:29Z</updated>
          <published>2003-12-13T08:29:29-04:00</published>
          <author>
            <name>Mark Pilgrim</name>
            <uri>http://example.org/</uri>
            <email>f8dy@example.com</email>
          </author>
          <contributor>
            <name>Sam Ruby</name>
          </contributor>
          <contributor>
            <name>Joe Gregorio</name>
          </contributor>
          <content type="xhtml" xml:lang="en"
            xml:base="http://diveintomark.org/">
            <div>
              <p><i>[Update: The Atom draft is finished.]</i></p>
            </div>
          </content>
        </entry>
      </feed>
      """

    let expected = RSSFeed(
      url: URL(string: "https://example.com/feed")!,
      title: "dive into mark",
      updated: Date(fromRFC3339: "2005-07-31T12:29:29Z"),
      entries: [
        RSSFeedEntry(
          id: "569adbfc-4c07-8f91-a78694e35315710c",
          title: "Atom draft-07 snapshot",
          links: [
            URL(string: "http://example.org/2005/04/02/atom")!,
            URL(string: "http://example.org/audio/ph34r_my_podcast.mp3")!,
          ],
          updated: Date(fromRFC3339: "2005-07-31T12:29:29Z")
        )
      ]
    )

    let actual = try RSSFeed(
      url: URL(string: "https://example.com/feed")!,
      data: Data(input.utf8), contentType: "application/atom+xml")
    XCTAssertNoDifference(expected, actual)

  }

  func testParseRSS() throws {
    // SEE: https://www.rssboard.org/rss-specification#sampleFiles
    let input = """
      <?xml version="1.0"?>
      <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
        <channel>
            <title>NASA Space Station News</title>
            <link>http://www.nasa.gov/</link>
            <description>A RSS news feed containing the latest NASA press releases on the International Space Station.</description>
            <language>en-us</language>
            <pubDate>Tue, 10 Jun 2003 04:00:00 GMT</pubDate>
            <lastBuildDate>Fri, 21 Jul 2023 09:04 EDT</lastBuildDate>
            <docs>https://www.rssboard.org/rss-specification</docs>
            <generator>Blosxom 2.1.2</generator>
            <managingEditor>neil.armstrong@example.com (Neil Armstrong)</managingEditor>
            <webMaster>sally.ride@example.com (Sally Ride)</webMaster>
            <atom:link href="https://www.rssboard.org/files/sample-rss-2.xml" rel="self" type="application/rss+xml" />
            <item>
              <title>Louisiana Students to Hear from NASA Astronauts Aboard Space Station</title>
              <link>http://www.nasa.gov/press-release/louisiana-students-to-hear-from-nasa-astronauts-aboard-space-station</link>
              <description>As part of the state's first Earth-to-space call, students from Louisiana will have an opportunity soon to hear from NASA astronauts aboard the International Space Station.</description>
              <pubDate>Fri, 21 Jul 2023 09:04 EDT</pubDate>
              <guid>http://www.nasa.gov/press-release/louisiana-students-to-hear-from-nasa-astronauts-aboard-space-station</guid>
            </item>
            <item>
              <description>NASA has selected KBR Wyle Services, LLC, of Fulton, Maryland, to provide mission and flight crew operations support for the International Space Station and future human space exploration.</description>
              <link>http://www.nasa.gov/press-release/nasa-awards-integrated-mission-operations-contract-iii</link>
              <pubDate>Thu, 20 Jul 2023 15:05 EDT</pubDate>
              <guid>http://www.nasa.gov/press-release/nasa-awards-integrated-mission-operations-contract-iii</guid>
            </item>
            <item>
              <title>NASA Expands Options for Spacewalking, Moonwalking Suits</title>
              <link>http://www.nasa.gov/press-release/nasa-expands-options-for-spacewalking-moonwalking-suits-services</link>
              <description>NASA has awarded Axiom Space and Collins Aerospace task orders under existing contracts to advance spacewalking capabilities in low Earth orbit, as well as moonwalking services for Artemis missions.</description>
              <enclosure url="http://www.nasa.gov/sites/default/files/styles/1x1_cardfeed/public/thumbnails/image/iss068e027836orig.jpg?itok=ucNUaaGx" length="1032272" type="image/jpeg" />
              <pubDate>Mon, 10 Jul 2023 14:14 EDT</pubDate>
              <guid>http://www.nasa.gov/press-release/nasa-expands-options-for-spacewalking-moonwalking-suits-services</guid>
            </item>
            <item>
              <title>NASA to Provide Coverage as Dragon Departs Station</title>
              <link>http://www.nasa.gov/press-release/nasa-to-provide-coverage-as-dragon-departs-station-with-science</link>
              <description>NASA is set to receive scientific research samples and hardware as a SpaceX Dragon cargo resupply spacecraft departs the International Space Station on Thursday, June 29.</description>
              <pubDate>Tue, 20 May 2003 08:56:02 GMT</pubDate>
              <guid>http://www.nasa.gov/press-release/nasa-to-provide-coverage-as-dragon-departs-station-with-science</guid>
            </item>
            <item>
              <title>NASA Plans Coverage of Roscosmos Spacewalk Outside Space Station</title>
              <link>http://liftoff.msfc.nasa.gov/news/2003/news-laundry.asp</link>
              <description>Compared to earlier spacecraft, the International Space Station has many luxuries, but laundry facilities are not one of them.  Instead, astronauts have other options.</description>
              <enclosure url="http://www.nasa.gov/sites/default/files/styles/1x1_cardfeed/public/thumbnails/image/spacex_dragon_june_29.jpg?itok=nIYlBLme" length="269866" type="image/jpeg" />
              <pubDate>Mon, 26 Jun 2023 12:45 EDT</pubDate>
              <guid>http://liftoff.msfc.nasa.gov/2003/05/20.html#item570</guid>
            </item>
        </channel>
      </rss>
      """

    let expected = RSSFeed(
      url: URL(string: "https://example.com/feed")!,
      title: "NASA Space Station News",
      updated: Date(fromRFC2822: "Fri, 21 Jul 2023 09:04 EDT"),
      entries: [
        RSSFeedEntry(
          id:
            "b54968ee-ef24-80c8-9ead1cb362947413",
          title:
            "Louisiana Students to Hear from NASA Astronauts Aboard Space Station",
          links: [
            URL(
              string:
                "http://www.nasa.gov/press-release/louisiana-students-to-hear-from-nasa-astronauts-aboard-space-station"
            )!
          ],
          summary:
            "As part of the state's first Earth-to-space call, students from Louisiana will have an opportunity soon to hear from NASA astronauts aboard the International Space Station.",
          updated: Date(fromRFC2822: "Fri, 21 Jul 2023 09:04 EDT")
        ),
        RSSFeedEntry(
          id:
            "b56823b6-c564-84c7-aa1c34f3d1bb0776",
          links: [
            URL(
              string:
                "http://www.nasa.gov/press-release/nasa-awards-integrated-mission-operations-contract-iii"
            )!
          ],
          summary:
            "NASA has selected KBR Wyle Services, LLC, of Fulton, Maryland, to provide mission and flight crew operations support for the International Space Station and future human space exploration.",
          updated: Date(fromRFC2822: "Thu, 20 Jul 2023 15:05 EDT")
        ),
        RSSFeedEntry(
          id:
            "0627f1a8-2c68-881f-a06b549e81203731",
          title:
            "NASA Expands Options for Spacewalking, Moonwalking Suits",
          links: [
            URL(
              string:
                "http://www.nasa.gov/press-release/nasa-expands-options-for-spacewalking-moonwalking-suits-services"
            )!
          ],
          summary:
            "NASA has awarded Axiom Space and Collins Aerospace task orders under existing contracts to advance spacewalking capabilities in low Earth orbit, as well as moonwalking services for Artemis missions.",
          updated: Date(fromRFC2822: "Mon, 10 Jul 2023 14:14 EDT")
        ),
        RSSFeedEntry(
          id:
            "548d95ed-607d-825c-bf9671e16ab6131a",
          title:
            "NASA to Provide Coverage as Dragon Departs Station",
          links: [
            URL(
              string:
                "http://www.nasa.gov/press-release/nasa-to-provide-coverage-as-dragon-departs-station-with-science"
            )!
          ],
          summary:
            "NASA is set to receive scientific research samples and hardware as a SpaceX Dragon cargo resupply spacecraft departs the International Space Station on Thursday, June 29.",
          updated: Date(fromRFC2822: "Tue, 20 May 2003 08:56:02 GMT")
        ),
        RSSFeedEntry(
          id:
            "4fcaeacd-bf84-8e67-a2faafcd34660883",
          title:
            "NASA Plans Coverage of Roscosmos Spacewalk Outside Space Station",
          links: [
            URL(
              string:
                "http://liftoff.msfc.nasa.gov/news/2003/news-laundry.asp"
            )!
          ],
          summary:
            "Compared to earlier spacecraft, the International Space Station has many luxuries, but laundry facilities are not one of them.  Instead, astronauts have other options.",
          updated: Date(fromRFC2822: "Mon, 26 Jun 2023 12:45 EDT")
        ),
      ]
    )

    let actual = try RSSFeed(
      url: URL(string: "https://example.com/feed")!,
      data: Data(input.utf8), contentType: "application/rss+xml")
    XCTAssertNoDifference(expected, actual)
  }

  func testParseRSS2() throws {
    // SEE: https://feeds.arstechnica.com/arstechnica/gadgets
    let input = """
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0"
        xmlns:content="http://purl.org/rss/1.0/modules/content/"
        xmlns:wfw="http://wellformedweb.org/CommentAPI/"
        xmlns:dc="http://purl.org/dc/elements/1.1/"
        xmlns:atom="http://www.w3.org/2005/Atom"
        xmlns:sy="http://purl.org/rss/1.0/modules/syndication/"
        xmlns:slash="http://purl.org/rss/1.0/modules/slash/"
      >
        <channel>
          <title>Title</title>
          <atom:link href="https://example.com/feed" rel="self" type="application/rss+xml" />
          <link>https://example.com</link>
          <description>Description.</description>
          <lastBuildDate>Wed, 05 Jun 2024 20:21:37 +0000</lastBuildDate>
          <language>en-US</language>
          <sy:updatePeriod>hourly </sy:updatePeriod>
          <sy:updateFrequency>1</sy:updateFrequency>
          <generator>https://example.com</generator>

          <image>
            <url>https://example.com/image.png</url>
            <title> Title</title>
            <link>https://example.com</link>
            <width>32</width>
            <height>32</height>
          </image>
          <item>
            <title>Title</title>
            <link>https://example.com</link>
            <comments>https://example.com/#comments</comments>
            <dc:creator><![CDATA[Scharon Harding]]></dc:creator>
            <pubDate>Wed, 05 Jun 2024 20:09:05 +0000</pubDate>
            <category><![CDATA[Tech]]></category>
            <guid isPermaLink="false">https://example.com/item</guid>
            <description><![CDATA[Description.]]></description>
            <content:encoded><![CDATA[<p>Content</p>]]></content:encoded>
            <wfw:commentRss>https://example.com/comments</wfw:commentRss>
            <slash:comments>122</slash:comments>
          </item>
        </channel>
      </rss>
      """

    let expected = RSSFeed(
      url: URL(string: "https://example.com/feed")!,
      title: "Title",
      updated: Date(fromRFC2822: "Wed, 05 Jun 2024 20:21:37 +0000"),
      entries: [
        RSSFeedEntry(
          id:
            "a24ed3ae-1ca8-8cfe-89b1aa98ce70f29f",
          title:
            "Title",
          links: [
            URL(
              string:
                "https://example.com"
            )!
          ],
          summary:
            "Description.",
          updated: Date(fromRFC2822: "Wed, 05 Jun 2024 20:09:05 +0000")
        )
      ]
    )

    let actual = try RSSFeed(
      url: URL(string: "https://example.com/feed")!,
      data: Data(input.utf8), contentType: "application/rss+xml")
    XCTAssertNoDifference(expected, actual)
  }

  func testParseJSONFeed() throws {
    let input = """
      {
        "version": "https://jsonfeed.org/version/1.1",
        "title": "My Example Feed",
        "home_page_url": "https://example.org/",
        "feed_url": "https://example.org/feed.json",
        "items": [
          {
              "id": "2",
              "content_text": "This is a second item.",
              "url": "https://example.org/second-item"
          },
          {
              "id": "1",
              "content_html": "<p>Hello, world!</p>",
              "url": "https://example.org/initial-post"
          }
        ]
      }
      """

    let expected = RSSFeed(
      url: URL(string: "https://example.com/feed")!,
      title: "My Example Feed",
      updated: nil,
      entries: [
        RSSFeedEntry(
          id: "4ef31782-bf47-87d3-ab62f8ba795e5dae",
          links: [URL(string: "https://example.org/second-item")!]
        ),
        RSSFeedEntry(
          id: "ac398901-680c-8d4c-9dddc5dccc5f8fc2",
          links: [URL(string: "https://example.org/initial-post")!]
        ),
      ])

    let actual = try RSSFeed(
      url: URL(string: "https://example.com/feed")!,
      data: Data(input.utf8), contentType: "application/feed+json")
    XCTAssertNoDifference(expected, actual)
  }
}
