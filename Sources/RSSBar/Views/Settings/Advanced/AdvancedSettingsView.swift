import Combine
import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers
import os

private let logger = Logger(
  subsystem: Bundle.main.bundleIdentifier!, category: "UI/Settings")

struct AdvancedSettingsView: View {
  @State private var presentResetDialog = false
  @State private var presentImportDialog = false
  @AppStorage("enableFaviconsFetching") private var enableFaviconsFetching =
    true

  @Environment(\.modelContext) var modelContext
  @Environment(\.updateIcon) var updateIcon

  var body: some View {
    Form {
      Section("Favicons") {
        Toggle(
          isOn: $enableFaviconsFetching
        ) {
          Text("Fetch favicons")
        }

        Button("Clear cache") {
          do {
            try DiskCache.shared.removeAll()
          } catch { logger.error("Failed to clear data") }
        }
      }

      Section("Data") {
        Button("Export...") {
          let panel = NSOpenPanel()
          panel.allowsMultipleSelection = false
          panel.canChooseDirectories = true
          panel.canChooseFiles = false
          panel.prompt = "Export"
          if panel.runModal() == .OK && panel.url != nil {
            try? exportModelData(to: panel.url!, modelContext: modelContext)
          }
        }
        Button("Import...") { presentImportDialog = true }
          .confirmationDialog(
            "Imported data will replace any existing data. Continue?",
            isPresented: $presentImportDialog
          ) {
            Button("Continue", role: .destructive) {
              let panel = NSOpenPanel()
              panel.allowsMultipleSelection = false
              panel.canChooseDirectories = false
              panel.allowedContentTypes = [UTType.json]
              panel.prompt = "Import"
              if panel.runModal() == .OK && panel.url != nil {
                do {
                  try importModelData(
                    from: panel.url!, modelContext: modelContext)
                } catch {
                  logger.error(
                    "Failed to import data: \(error, privacy: .public)")
                }
                updateIcon?()
              }
            }
            .keyboardShortcut(.delete)
          } message: {
            Text(
              "All existing groups, feeds and history will be removed."
            )
          }
          .dialogIcon(Image(systemName: "square.and.arrow.down.fill"))
      }

      Section("Actions") {
        Button("Reset...") { presentResetDialog = true }
          .confirmationDialog(
            "Are you sure you want to reset all settings and data?",
            isPresented: $presentResetDialog
          ) {
            Button("Reset", role: .destructive) {
              do {
                try resetModelData(modelContext: modelContext)
              } catch {
                logger.error(
                  "Failed to reset data: \(error, privacy: .public)")
              }
              // TODO: Reset settings to default
              updateIcon?()
            }
            .keyboardShortcut(.delete)
          } message: {
            Text(
              "All groups, feeds and history will be removed."
            )
          }
          .dialogIcon(Image(systemName: "arrow.clockwise.circle.fill"))
      }
    }
    .formStyle(.grouped)
  }
}
