import SwiftUI
import UniformTypeIdentifiers

struct OpenFileDialog: ViewModifier {
  var prompt: String
  @Binding var isPresented: Bool
  var callback: (_ ok: Bool, _ url: URL?) -> Void

  let panel: NSOpenPanel

  init(
    _ prompt: String,
    allowedContentTypes: [UTType],
    isPresented: Binding<Bool>,
    callback: @escaping (_ ok: Bool, _ url: URL?) -> Void
  ) {
    self.prompt = prompt
    self._isPresented = isPresented
    self.callback = callback

    // TODO: This slows the time to render the view the first time
    let panel = NSOpenPanel()
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    panel.allowedContentTypes = allowedContentTypes
    panel.prompt = prompt
    panel.canCreateDirectories = true
    self.panel = panel
  }

  func body(content: Content) -> some View {
    content.onChange(of: isPresented) {
      if isPresented {
        DispatchQueue.main.async {
          let result = panel.runModal()
          callback(result == .OK, panel.url)
          isPresented = false
        }
      } else {
        panel.close()
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
        prompt, allowedContentTypes: allowedContentTypes, isPresented: isPresented, callback: callback
      ))
  }
}
