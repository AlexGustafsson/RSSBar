import Combine
import Foundation
import SwiftData
import SwiftUI
import os

private let logger = Logger(
  subsystem: Bundle.main.bundleIdentifier!, category: "UI/Settings")

struct AdvancedSettingsView: View {
  @State private var presentResetDialog = false
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

      Section("Actions") {
        Button("Reset...") { presentResetDialog = true }
          .confirmationDialog(
            "Are you sure you want to reset all settings and data?",
            isPresented: $presentResetDialog
          ) {
            Button("Reset", role: .destructive) {
              do {
                // NOTE: Should coalesce delete on FeedGroup and Feed, but let's
                // make sure all potential dangling items are deleted as well
                try modelContext.delete(model: FeedGroup.self)
                try modelContext.delete(model: Feed.self)
                try modelContext.delete(model: FeedItem.self)
                try DiskCache.shared.removeAll()  // TODO: Reset settings to default
                updateIcon?()
              } catch { logger.error("Failed to clear data") }
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
