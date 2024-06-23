import Combine
import SwiftUI

private struct SizePreferenceKey: PreferenceKey {
  static var defaultValue: CGSize = .zero
  static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

extension View {
  func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
    background(
      GeometryReader { geometryProxy in
        Color.clear
          .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
      }
    )
    .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
  }
}

extension View {
  func onChange<V, S>(
    of value: V,
    for dueTime: S.SchedulerTimeType.Stride,
    scheduler: S,
    options: S.SchedulerOptions? = nil,
    _ action: @escaping (_ oldValue: V, _ newValue: V) -> Void
  ) -> some View where V: Equatable, S: Scheduler {
    // TODO: Do we need to store cancellables?
    print("mounted")
    let publisher = PassthroughSubject<V, Error>()
    publisher.debounce(for: dueTime, scheduler: scheduler, options: options)

    return self.onChange(of: value) {
      publisher.send(value)
    }
  }
}
