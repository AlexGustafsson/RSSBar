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

// "Are you sure you want to reset all settings and data?",
//             isPresented: $presentResetDialog

//             let panel = NSOpenPanel()
// panel.allowsMultipleSelection = false
// panel.canChooseDirectories = false
// panel.allowedContentTypes = [UTType.json]
// panel.prompt = "Import"
// if panel.runModal() == .OK && panel.url != nil {
//   do {
//     try importModelData(
//       from: panel.url!, modelContext: modelContext)
//   } catch {
//     logger.error(
//       "Failed to import data: \(error, privacy: .public)")
//   }
//   updateIcon?()
// }

// .confirmationDialog(
//   "Imported data will replace any existing data. Continue?",
//   isPresented: $presentImportDialog
// ) {
//   Button("Continue", role: .destructive) {
//     let panel = NSOpenPanel()
//     panel.allowsMultipleSelection = false
//     panel.canChooseDirectories = false
//     panel.allowedContentTypes = [UTType.json]
//     panel.prompt = "Import"
//     if panel.runModal() == .OK && panel.url != nil {
//       do {
//         try importModelData(
//           from: panel.url!, modelContext: modelContext)
//       } catch {
//         logger.error(
//           "Failed to import data: \(error, privacy: .public)")
//       }
//       updateIcon?()
//     }
//   }
//   .keyboardShortcut(.delete)
// } message: {
//   Text(
//     "All existing groups, feeds and history will be removed."
//   )
// }
// .dialogIcon(Image(systemName: "square.and.arrow.down.fill"))
