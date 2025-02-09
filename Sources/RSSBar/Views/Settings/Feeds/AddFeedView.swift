import Combine
import Foundation
import RSSKit
import SwiftData
import SwiftUI
import os

private let logger = Logger(
  subsystem: Bundle.main.bundleIdentifier!, category: "UI/AddFeed")

private struct FormsDescription: Decodable {
  let sections: [FormSection]
}

private struct FormSection: Decodable {
  let name: String
  let items: [FormItem]
}

private struct FormItem: Decodable {
  let title: String
  let description: String
  let template: String
  let components: [FormComponent]
}

private struct URLTemplate {
  public static func render(_ template: String, with values: [String: Any])
    -> String?
  {
    let regexp = #/\${([^}]+)}/#
    let matches = template.matches(of: regexp)

    var variables = Set<String>()
    for match in matches.reversed() {
      variables.insert(String(match.output.1))
    }

    // TODO: Doesn't handle verbatim "${}" in URLs
    var result = template
    for variable in variables {
      guard let value = values[variable] as? String else {
        return nil
      }

      if value == "" {
        return nil
      }

      result.replace(try! Regex("\\${\(variable)}"), with: value)
    }

    return result
  }
}

private struct FormItemView: View {
  @Binding var formItem: FormItem
  @Binding var form: FeedForm

  @State var i = Int.random(in: 0...50)

  @MainActor private func updateForm() {
    self.form.url =
      URLTemplate.render(
        self.formItem.template, with: self.form.kv) ?? ""
  }

  var body: some View {
    Section {
      ForEach(formItem.components, id: \.name) { component in
        switch component.type {
        case "text":
          TextField(
            component.label,
            text: Binding(
              get: {
                form.kv[component.name] as! String? ?? ""
              },
              set: { newValue in
                form.kv[component.name] = newValue
                updateForm()
              }),
            prompt: Text(component.examples[i % component.examples.count])
          )
        default:
          Text("Invalid component type!")
        }
      }
    }
  }
}

private struct FormComponent: Decodable {
  let type: String
  let name: String
  let label: String
  let examples: [String]
}

@Observable private class FeedForm {
  var name: String = ""
  var url: String = "" {
    didSet { self.urlPublisher.send(url) }
  }
  var feed: RSSFeed? = nil
  var isFetching = false
  var fetchError: String?
  var fetchWarning: String?

  var kv: [String: Any] = [:]

  private var urlPublisher = PassthroughSubject<String, Never>()
  private var cancelables = Set<AnyCancellable>()

  private var fetchTask: Task<(), Never>?

  init() {
    // Immediately invalidate the feed
    self.urlPublisher.removeDuplicates()
      .sink { [self] _ in
        if self.feed != nil && self.name == self.feed!.title {
          self.name = ""
        }
        self.feed = nil
      }
      .store(in: &cancelables)

    // After debounce, try to fetch the feed for validation
    self.urlPublisher
      .removeDuplicates()
      .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
      .sink { [self] _ in
        guard let url = self.absoluteUrl else {
          self.feed = nil
          if url == "" {
            self.fetchError = nil
          } else {
            self.fetchError = "Invalid URL"
          }
          return
        }

        if let currentTask = self.fetchTask {
          currentTask.cancel()
        }
        self.fetchTask = Task {
          do {
            self.isFetching = true
            self.fetchError = nil
            defer {
              self.isFetching = false
            }
            let feed = try await RSSFeed.init(contentsOf: url)
            if !Task.isCancelled {
              self.feed = feed
              if self.name == "" {
                self.name = self.feed?.title ?? ""
              }
              if feed.url.scheme == "http" {
                self.fetchWarning =
                  "Insecure transport used - use HTTPS if possible"
              }
            }
          } catch {
            if let rssError = error as? RSSError {
              switch rssError {
              case RSSError.invalidContentType(let contentType):
                self.fetchError =
                  "Invalid content for resource of type \(contentType)"
              case RSSError.unknownContentType:
                self.fetchError = "Failed to identify content type"
              case RSSError.unexpectedStatusCode(let statusCode):
                switch statusCode {
                case 404:
                  self.fetchError = "The feed was not found"
                default:
                  self.fetchError =
                    "Failed to fetch resource - got status code \(statusCode)"
                }
              default:
                self.fetchError = "Failed to fetch the feed"
                logger.error("Failed to fetch feed \(error, privacy: .public)")
              }
            } else {
              let nsError = error as NSError
              switch nsError.domain {
              case NSURLErrorDomain:
                switch nsError.code {
                case NSURLErrorCannotFindHost:
                  self.fetchError = "The domain was not found"
                default:
                  self.fetchError =
                    "An unknown error occurred when fetching the feed"
                  logger.error(
                    "Failed to fetch feed \(error, privacy: .public)")
                }
              default:
                self.fetchError =
                  "An unknown error occurred when fetching the feed"
                logger.error("Failed to fetch feed \(error, privacy: .public)")
              }
            }
            // TODO: Use typed errors from Swift 6?
          }
        }
      }
      .store(
        in: &cancelables
      )
  }

  func clear() {
    self.name = ""
    self.url = ""
    self.feed = nil
    self.kv = [:]
  }

  var absoluteUrl: URL? {
    guard let url = URL(string: self.url) else {
      return nil
    }

    let isHTTP = url.scheme?.hasPrefix("http") ?? false
    let isHTTPS = url.scheme?.hasPrefix("https") ?? false
    let hasDomain = url.host() != nil

    return (isHTTP || isHTTPS) && hasDomain ? url : nil
  }

  var isValid: Bool {
    return feed != nil && name != ""
  }
}

private struct AddFeedURLView: View {
  @Binding var form: FeedForm

  var body: some View {
    Section {
      TextField(
        "Feed", text: $form.url,
        prompt: Text("https://example.com/feed.atom")
      )
    }
  }
}

struct AddFeedView: View {
  @State var group: FeedGroup

  @State private var form: FeedForm = FeedForm()
  @State private var feed: RSSFeed? = nil

  @Environment(\.dismiss) var dismiss
  @Environment(\.modelContext) var modelContext
  @Environment(\.updateIcon) var updateIcon

  @State private var forms: FormsDescription
  @State private var selectedFormItem: FormItem

  init(group: FeedGroup) {
    self.group = group

    let formsURL = Bundle.main.url(
      forResource: "feed-forms", withExtension: "json")!

    let decoder = JSONDecoder()

    let forms: FormsDescription = try! decoder.decode(
      FormsDescription.self, from: Data(contentsOf: formsURL))

    self.forms = forms
    self.selectedFormItem = forms.sections[0].items[0]
  }

  var body: some View {
    VStack(spacing: 0) {
      Form {
        Section {
          HStack {
            Favicon(
              url: form.feed?.url,
              fallbackCharacter: form.name,
              fallbackSystemName: "list.bullet"
            )
            .frame(width: 48, height: 48)
            VStack(alignment: .leading) {
              TextField("Name", text: $form.name, prompt: Text("Name"))
                .textFieldStyle(.plain).labelsHidden().font(.headline)
                .foregroundStyle(.secondary)
              HStack {
                TruncatedText(form.url).font(.footnote)
                  .foregroundStyle(.secondary)
                  .frame(maxWidth: .infinity, alignment: .leading)
                if form.isFetching {
                  ProgressView().scaleEffect(0.5)
                } else if let fetchError = form.fetchError {
                  Image(systemName: "xmark.circle").foregroundStyle(.red)
                    .help(fetchError)
                } else if let fetchWarning = form.fetchWarning {
                  Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .help(fetchWarning)
                }
              }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
          }
        } header: {
          Menu {
            ForEach(self.forms.sections, id: \.name) { section in
              let items = ForEach(section.items, id: \.description) { item in
                Button(item.description) {
                  selectedFormItem = item
                  // Clear form key value state
                  form.clear()
                }
              }

              if section.name == "" {
                items
              } else {
                Section(section.name) {
                  items
                }
              }
            }
          } label: {
            Text(selectedFormItem.title).font(.headline)
          }
          .menuStyle(.borderlessButton)
        }

        FormItemView(formItem: $selectedFormItem, form: $form)
      }
      .padding(5).formStyle(.grouped)

      Divider()

      // Footer
      HStack {
        Spacer()
        Button(
          "Cancel"
        ) {
          dismiss()
        }
        .keyboardShortcut(.cancelAction)
        Button("Add") {
          try? modelContext.addFeed(
            groupId: group.id,
            feed: Feed(name: form.name, url: form.absoluteUrl!))
          try? modelContext.save()
          dismiss()
          Task {
            let fetcher = FeedFetcher(modelContainer: modelContext.container)
            try await fetcher.fetchFeeds()
            updateIcon()
          }
        }
        .keyboardShortcut(.defaultAction)
        .disabled(!form.isValid)
      }
      .padding(20)
    }
    .frame(width: 420, height: 420)
  }
}
