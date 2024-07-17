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
  @State private var presentImportConfirmationDialog = false
  @State private var presentImportDialog = false
  @State private var presentExportDialog = false

  @AppStorage(UserDefaults.Keys.enableFaviconsFetching.rawValue) private var enableFaviconsFetching =
    true

  @Environment(\.updateIcon) var updateIcon

  @Environment(\.modelContext) private var modelContext

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
          presentExportDialog = true
        }
        .saveFileDialog(
          "Export", fileName: "RSSBar Export.json",
          isPresented: $presentExportDialog
        ) {
          ok, url in
          if ok {
            try? modelContext.exportData(to: url!)
          }
        }
        Button("Import...") { presentImportConfirmationDialog = true }
          .confirmationDialog(
            "Imported data will replace any existing data. Continue?",
            isPresented: $presentImportConfirmationDialog
          ) {
            Button("Continue", role: .destructive) {
              presentImportDialog = true
            }
            .keyboardShortcut(.delete)
            .openFileDialog(
              "Import", allowedContentTypes: [.json],
              isPresented: $presentImportDialog
            ) { ok, url in
              if ok {
                do {
                  try modelContext.importData(from: url!)
                } catch {
                  logger.error(
                    "Failed to import data: \(error, privacy: .public)")
                }
                // updateIcon?()
              }
            }
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
                try modelContext.reset()
                try DiskCache.shared.removeAll()
                // TODO: This updates the UI the first time, but not the second.
                // Doesn't matter if we reload the window
                UserDefaults.standard.reset()
              } catch {
                logger.error(
                  "Failed to reset data: \(error, privacy: .public)")
              }
              // updateIcon?()
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
