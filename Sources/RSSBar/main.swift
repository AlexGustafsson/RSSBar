import AppKit
import os

private let logger = Logger(
  subsystem: Bundle.main.bundleIdentifier ?? "", category: "UI/Main")

class App {
  static func main() {
    logger.info("Initiating application")
    let app = NSApplication.shared

    let appDelegate = AppDelegate()
    app.delegate = appDelegate

    logger.info("Starting application")
    app.run()

    logger.info("Application closed")

  }
}

App
  .main()
