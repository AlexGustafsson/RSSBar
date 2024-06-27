import SwiftUI

struct CountBadge: View {
  var value: Int

  private let size = 16.0

  var body: some View {
    ZStack {
      Capsule().fill(.blue)
        .frame(
          width: size * widthMultplier(), height: size, alignment: .topTrailing)

      if value < 100 {
        Text("\(value)").font(Font.caption)
      } else {
        Text("99+").font(Font.caption)
          .frame(
            width: size * widthMultplier(), height: size, alignment: .center)
      }
    }
    .opacity(value == 0 ? 0 : 1)
  }

  func widthMultplier() -> Double {
    if value < 10 {
      return 1.2
    } else if value < 100 {
      return 1.5
    } else {
      return 2.0
    }
  }
}
