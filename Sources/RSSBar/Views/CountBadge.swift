import SwiftUI

struct CountBadge: View {
  var value: Int

  private let size = 16.0

  var body: some View {
    ZStack {
      Capsule().fill(.primary.opacity(0.1))
        .frame(
          width: size * widthMultplier(), height: size, alignment: .topTrailing)

      if hasTwoOrLessDigits() {
        Text("\(value)").foregroundColor(.primary).font(Font.caption)
      } else {
        Text("99+").foregroundColor(.primary).font(Font.caption)
          .frame(
            width: size * widthMultplier(), height: size, alignment: .center)
      }
    }
    .opacity(value == 0 ? 0 : 1)
  }

  // showing more than 99 might take too much space, rather display something like 99+
  func hasTwoOrLessDigits() -> Bool { return value < 100 }

  func widthMultplier() -> Double {
    if value < 10 {
      // one digit
      return 1.0
    } else if value < 100 {
      // two digits
      return 1.5
    } else {
      // too many digits, showing 99+
      return 2.0
    }
  }
}
