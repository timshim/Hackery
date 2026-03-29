//
//  FeedViewModel.swift
//  Hackery
//
//  Created by Tim Shim on 6/10/19.
//  Copyright © 2019 Tim Shim. All rights reserved.
//

import SwiftUI
import SwiftSoup

private let baseURL = "https://hacker-news.firebaseio.com/v0"

@MainActor
@Observable
final class FeedViewModel {

  var stories = [Story]()
  var comments = [Comment]()
  var isLoading = false
  var error: String?

  private let decoder = JSONDecoder()
  private var currentTask: Task<Void, Never>?

  func loadTopStories() async {
    currentTask?.cancel()
    guard let url = URL(string: "\(baseURL)/topstories.json") else { return }

    isLoading = true
    error = nil
    stories.removeAll()

    let task = Task {
      do {
        let (data, _) = try await URLSession.shared.data(from: url)
        let storyIds = try decoder.decode([Int].self, from: data)

        let fetched = try await withThrowingTaskGroup(of: (Int, Story?).self) { group in
          for (index, id) in storyIds.prefix(100).enumerated() {
            group.addTask { [decoder] in
              try Task.checkCancellation()
              guard let itemURL = URL(string: "\(baseURL)/item/\(id).json") else {
                return (index, nil)
              }
              let (itemData, _) = try await URLSession.shared.data(from: itemURL)
              let item = try decoder.decode(HNItem.self, from: itemData)
              guard item.deleted != true, item.dead != true else { return (index, nil) }
              return (index, Story(from: item))
            }
          }

          var results = [(Int, Story?)]()
          for try await result in group {
            results.append(result)
          }
          return results
            .sorted { $0.0 < $1.0 }
            .compactMap { $0.1 }
        }

        if !Task.isCancelled {
          stories = fetched
        }
      } catch is CancellationError {
        // Task was cancelled, no-op
      } catch {
        self.error = error.localizedDescription
      }

      isLoading = false
    }
    currentTask = task
    await task.value
  }

  func loadComments(for story: Story) async {
    currentTask?.cancel()
    isLoading = true
    error = nil
    comments.removeAll()

    let task = Task {
      do {
        let fetched = try await withThrowingTaskGroup(of: (Int, Comment?).self) { group in
          for (index, id) in story.kids.enumerated() {
            group.addTask { [decoder] in
              try Task.checkCancellation()
              guard let url = URL(string: "\(baseURL)/item/\(id).json") else {
                return (index, nil)
              }
              let (data, _) = try await URLSession.shared.data(from: url)
              let item = try decoder.decode(HNItem.self, from: data)

              var parsedText: String?
              if let text = item.text {
                parsedText = Self.parseHTML(text)
              }

              return (index, Comment(from: item, parsedText: parsedText))
            }
          }

          var results = [(Int, Comment?)]()
          for try await result in group {
            results.append(result)
          }
          return results
            .sorted { $0.0 < $1.0 }
            .compactMap { $0.1 }
        }

        if !Task.isCancelled {
          comments = fetched.filter { !$0.deleted && !$0.dead }
        }
      } catch is CancellationError {
        // Task was cancelled, no-op
      } catch {
        self.error = error.localizedDescription
      }

      isLoading = false
    }
    currentTask = task
    await task.value
  }

  nonisolated private static func parseHTML(_ html: String) -> String {
    do {
      let doc = try SwiftSoup.parseBodyFragment(html)
      for p in try doc.select("p") {
        try p.before("\\n\\n")
      }
      for br in try doc.select("br") {
        try br.before("\\n")
      }
      for link in try doc.select("a[href]") {
        let href = try link.attr("href")
        let text = try link.text()
        try link.text(text == href ? href : "\(text) (\(href))")
      }
      return try doc.text()
        .replacingOccurrences(of: "\\n", with: "\n")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    } catch {
      return html
    }
  }
}
