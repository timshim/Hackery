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
private let pageSize = 25

@MainActor
@Observable
final class FeedViewModel {

  var stories = [Story]()
  var comments = [Comment]()
  var isLoading = false
  var isLoadingMore = false
  var error: String?

  private let decoder = JSONDecoder()
  private var currentTask: Task<Void, Never>?
  private var allStoryIds = [Int]()
  private var loadedCount = 0

  func loadTopStories(refresh: Bool = false) {
    currentTask?.cancel()
    guard let url = URL(string: "\(baseURL)/topstories.json") else { return }

    if refresh {
      stories.removeAll()
      allStoryIds.removeAll()
      loadedCount = 0
    } else if stories.isEmpty, let cached = StoryCache.load() {
      stories = cached
    }

    isLoading = true
    error = nil

    currentTask = Task {
      do {
        let (data, _) = try await URLSession.shared.data(from: url)
        try Task.checkCancellation()
        allStoryIds = try decoder.decode([Int].self, from: data)
        loadedCount = 0

        let firstPage = try await fetchStories(ids: Array(allStoryIds.prefix(pageSize)))

        try Task.checkCancellation()
        stories = firstPage
        loadedCount = pageSize
        StoryCache.save(firstPage)
      } catch is CancellationError {
        // no-op
      } catch {
        self.error = error.localizedDescription
      }

      isLoading = false
    }
  }

  func loadMoreStories() async {
    guard !isLoadingMore,
          loadedCount < allStoryIds.count else { return }

    isLoadingMore = true

    let nextIds = Array(allStoryIds.dropFirst(loadedCount).prefix(pageSize))
    do {
      let more = try await fetchStories(ids: nextIds)
      stories.append(contentsOf: more)
      loadedCount += pageSize
      StoryCache.save(stories)
    } catch {
      self.error = error.localizedDescription
    }

    isLoadingMore = false
  }

  var hasMoreStories: Bool {
    loadedCount < allStoryIds.count
  }

  func loadComments(for story: Story) {
    currentTask?.cancel()
    isLoading = true
    error = nil
    comments.removeAll()

    currentTask = Task {
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

        try Task.checkCancellation()
        comments = fetched.filter { !$0.deleted && !$0.dead }
      } catch is CancellationError {
        // no-op
      } catch {
        self.error = error.localizedDescription
      }

      isLoading = false
    }
  }

  // MARK: - Private

  private func fetchStories(ids: [Int]) async throws -> [Story] {
    try await withThrowingTaskGroup(of: (Int, Story?).self) { group in
      for (index, id) in ids.enumerated() {
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
