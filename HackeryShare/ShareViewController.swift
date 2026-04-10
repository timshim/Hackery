//
//  ShareViewController.swift
//  HackeryShare
//
//  Receives a URL from Safari's share sheet, searches HN Algolia for
//  a matching discussion, and opens the main app at hackery://story/{id}.
//

import UIKit
import UniformTypeIdentifiers

@objc(ShareViewController)
class ShareViewController: UIViewController {

  private let spinner = UIActivityIndicatorView(style: .large)
  private let statusLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    spinner.translatesAutoresizingMaskIntoConstraints = false
    spinner.startAnimating()
    view.addSubview(spinner)

    statusLabel.translatesAutoresizingMaskIntoConstraints = false
    statusLabel.font = .preferredFont(forTextStyle: .subheadline)
    statusLabel.textColor = .secondaryLabel
    statusLabel.textAlignment = .center
    statusLabel.text = "Searching Hacker News..."
    view.addSubview(statusLabel)

    NSLayoutConstraint.activate([
      spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
      statusLabel.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 12),
      statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
    ])

    extractURL { [weak self] url in
      guard let self, let url else {
        self?.finish(error: "No URL found")
        return
      }
      self.searchAlgolia(for: url)
    }
  }

  // MARK: - URL Extraction

  private func extractURL(completion: @escaping (URL?) -> Void) {
    guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
      completion(nil)
      return
    }
    for item in items {
      for provider in item.attachments ?? [] {
        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
          provider.loadItem(forTypeIdentifier: UTType.url.identifier) { data, _ in
            DispatchQueue.main.async {
              completion(data as? URL)
            }
          }
          return
        }
      }
    }
    completion(nil)
  }

  // MARK: - Algolia Search

  private func searchAlgolia(for url: URL) {
    let query = url.absoluteString
      .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    let algoliaURL = URL(
      string: "https://hn.algolia.com/api/v1/search?query=\(query)&restrictSearchableAttributes=url&hitsPerPage=1"
    )!

    URLSession.shared.dataTask(with: algoliaURL) { [weak self] data, _, error in
      DispatchQueue.main.async {
        guard let self else { return }
        guard let data, error == nil,
              let response = try? JSONDecoder().decode(AlgoliaResponse.self, from: data),
              let hit = response.hits.first else {
          self.showNotFound(originalURL: url)
          return
        }

        let storyId = hit.objectID
        if let deepLink = URL(string: "hackery://story/\(storyId)") {
          self.openContainerApp(url: deepLink)
        } else {
          self.finish(error: nil)
        }
      }
    }.resume()
  }

  // MARK: - Open Container App

  private func openContainerApp(url: URL) {
    // `open(_:)` is available on NSExtensionContext starting iOS 18.2 (SE-0450).
    // For older OS, we respond via UIResponder chain.
    var responder: UIResponder? = self
    while let r = responder {
      if r.responds(to: sel_registerName("openURL:")) {
        r.perform(sel_registerName("openURL:"), with: url)
        break
      }
      responder = r.next
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
      self?.finish(error: nil)
    }
  }

  // MARK: - Not Found

  private func showNotFound(originalURL: URL) {
    spinner.stopAnimating()
    statusLabel.text = "No discussion found on Hacker News"

    let button = UIButton(type: .system)
    button.setTitle("Done", for: .normal)
    button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
    view.addSubview(button)

    NSLayoutConstraint.activate([
      button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      button.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
    ])
  }

  @objc private func dismissTapped() {
    finish(error: nil)
  }

  private func finish(error: String?) {
    if let error {
      statusLabel.text = error
      spinner.stopAnimating()
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
        self?.extensionContext?.completeRequest(returningItems: nil)
      }
    } else {
      extensionContext?.completeRequest(returningItems: nil)
    }
  }
}
