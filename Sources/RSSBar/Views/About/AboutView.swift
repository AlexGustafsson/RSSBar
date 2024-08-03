import Foundation
import SwiftUI

struct AboutView: View {
  private let applicationName =
    Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? ""
  private let applicationVersion =
    Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
  private let icon = Bundle.main.image(forResource: "icon.png")!

  var body: some View {
    VStack(alignment: .center) {
      Image(nsImage: icon ?? NSImage()).resizable().scaledToFit()
        .frame(
          width: 128.0, height: 128.0)
      Text(applicationName).font(.headline)
      Text("App version: v\(applicationVersion)").font(.footnote)
      VStack {
        Text("\(applicationName) is Free Open Source Software.")
        Link(
          "Contribute on GitHub",
          destination: URL(string: "https://github.com/AlexGustafsson/rssbar")!
        )
        .onHover { isHovered in
          DispatchQueue.main.async {
            if isHovered {
              NSCursor.pointingHand.push()
            } else {
              NSCursor.pop()
            }
          }
        }
      }
      .font(.body).padding()
    }
    .padding()
  }
}
