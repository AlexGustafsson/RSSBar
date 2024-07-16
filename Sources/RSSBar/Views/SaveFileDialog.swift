import SwiftUI

struct SaveFileDialog: ViewModifier {
  let prompt: String
  let fileName: String?
  @Binding var isPresented: Bool
  let callback: (_ ok: Bool, _ url: URL?) -> Void

  init(
    _ prompt: String,
    fileName: String? = nil,
    isPresented: Binding<Bool>,
    callback: @escaping (_ ok: Bool, _ url: URL?) -> Void
  ) {
    self.prompt = prompt
    self.fileName = fileName
    self._isPresented = isPresented
    self.callback = callback
  }

  func body(content: Content) -> some View {
    content.onChange(of: isPresented) {
      if isPresented {
        DispatchQueue.main.schedule {
          let panel = NSSavePanel()
          panel.prompt = prompt
          panel.canCreateDirectories = true
          panel.nameFieldStringValue = fileName ?? ""
          let result = panel.runModal()
          callback(result == .OK, panel.url)
          isPresented = false
        }
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
