import SwiftUI

struct SaveFileDialog: ViewModifier {
  var prompt: String
  @Binding var isPresented: Bool
  var callback: (_ ok: Bool, _ url: URL?) -> Void

  let panel: NSSavePanel

  init(
    _ prompt: String,
    fileName: String? = nil,
    isPresented: Binding<Bool>,
    callback: @escaping (_ ok: Bool, _ url: URL?) -> Void
  ) {
    self.prompt = prompt
    self._isPresented = isPresented
    self.callback = callback

    // TODO: This slows the time to render the view the first time
    let panel = NSSavePanel()
    panel.prompt = prompt
    panel.canCreateDirectories = true
    panel.nameFieldStringValue = fileName ?? ""
    self.panel = panel
  }

  func body(content: Content) -> some View {
    content.onChange(of: isPresented) {
      if isPresented {
        let result = panel.runModal()
        callback(result == .OK, panel.url)
        isPresented = false
      } else {
        panel.close()
      }
    }
  }
}

extension View {
  func saveFileDialog(
    _ prompt: String,
    fileName: String?,
    isPresented: Binding<Bool>,
    callback: @escaping (_ ok: Bool, _ url: URL?) -> Void
  )
    -> some View
  {
    modifier(
      SaveFileDialog(
        prompt, fileName: fileName, isPresented: isPresented, callback: callback
      ))
  }
}
