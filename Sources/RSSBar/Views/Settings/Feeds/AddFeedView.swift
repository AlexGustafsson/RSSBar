import Combine
import Foundation
import RSSKit
import SwiftData
import SwiftUI
import os

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

  private func updateForm() {
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

  var kv: [String: Any] = [:]

  private var urlPublisher = PassthroughSubject<String, Never>()
  private var cancelables = Set<AnyCancellable>()

  init() {
    self.urlPublisher
      .removeDuplicates()
      .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
      .sink { [self] _ in
        guard let url = self.absoluteUrl else {
          self.feed = nil
          return
        }

        // TODO: Cancel if run again
        Task {
          do {
            self.feed = try await RSSFeed.init(contentsOf: url)
            if self.name == "" {
              self.name = self.feed?.title ?? ""
            }
          } catch {
            // TODO: Use typed errors from Swift 6?
            // TODO: Show errors
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

  @Environment(\.modelContext) var modelContext
  @Environment(\.dismiss) var dismiss
  @Environment(\.fetchFeeds) var fetchFeeds

  @State private var forms: FormsDescription
  @State private var selectedFormItem: FormItem

  init(group: FeedGroup) {
    self.group = group

    let formsURL = Bundle.module.url(
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
              Text(form.url).font(.footnote).foregroundStyle(.secondary)
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
          withAnimation {
            let feed = Feed(name: form.name, url: form.absoluteUrl!)
            var s = group.feeds.sorted(by: { $0.order < $1.order })
            s.append(feed)
            for (index, item) in s.enumerated() { item.order = index }
            group.feeds = s
            try? modelContext.save()
            dismiss()
            Task { await fetchFeeds?(ignoreSchedule: false) }
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
