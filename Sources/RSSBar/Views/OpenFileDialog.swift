import SwiftUI
import UniformTypeIdentifiers

struct OpenFileDialog: ViewModifier {
  let prompt: String
  @Binding var isPresented: Bool
  let callback: (_ ok: Bool, _ url: URL?) -> Void
  let allowedContentTypes: [UTType]

  init(
    _ prompt: String,
    allowedContentTypes: [UTType],
    isPresented: Binding<Bool>,
    callback: @escaping (_ ok: Bool, _ url: URL?) -> Void
  ) {
    self.prompt = prompt
    self.allowedContentTypes = allowedContentTypes
    self._isPresented = isPresented
    self.callback = callback
  }

  func body(content: Content) -> some View {
    content.onChange(of: isPresented) {
      if isPresented {
        DispatchQueue.main.async {
          let panel = NSOpenPanel()
          panel.canChooseDirectories = false
          panel.canChooseFiles = true
          panel.allowedContentTypes = allowedContentTypes
          panel.prompt = prompt
          panel.canCreateDirectories = true

          let result = panel.runModal()
          callback(result == .OK, panel.url)
          isPresented = false
        }
      }
    }
  }
}

extension View {
  func openFileDialog(
    _ prompt: String,
    allowedContentTypes: [UTType],
    isPresented: Binding<Bool>,
    callback: @escaping (_ ok: Bool, _ url: URL?) -> Void
  )
    -> some View
  {
    modifier(
      OpenFileDialog(
        prompt, allowedContentTypes: allowedContentTypes,
        isPresented: isPresented, callback: callback
      ))
  }
}
