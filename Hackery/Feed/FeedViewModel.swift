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
private let commentPageSize = 3
private let maxCommentDepth = 3

@MainActor
@Observable
final class FeedViewModel {

  var stories = [Story]()
  var comments = [Comment]()
  var isLoading = false
  var isLoadingMore = false
  var isLoadingMoreComments = false
  var error: String?

  private let decoder = JSONDecoder()
  private var currentTask: Task<Void, Never>?
  private var allStoryIds = [Int]()
  private var loadedCount = 0
  private var allTopLevelCommentIds = [Int]()
  private var loadedCommentCount = 0

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
        setError(error)
      }

      isLoading = false
    }
  }

  func loadMoreStories() async {
    guard !isLoadingMore,
          loadedCount < allStoryIds.count else { return }

    isLoadingMore = true
    error = nil

    let nextIds = Array(allStoryIds.dropFirst(loadedCount).prefix(pageSize))
    do {
      let more = try await fetchStories(ids: nextIds)
      stories.append(contentsOf: more)
      loadedCount += pageSize
      StoryCache.save(stories)
    } catch is CancellationError {
      // no-op
    } catch {
      setError(error)
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
    allTopLevelCommentIds = story.kids
    loadedCommentCount = 0

    currentTask = Task {
      do {
        let firstBatch = Array(allTopLevelCommentIds.prefix(commentPageSize))
        let fetched = try await fetchCommentTree(ids: firstBatch, depth: 0)

        try Task.checkCancellation()
        comments = fetched
        loadedCommentCount = commentPageSize
      } catch is CancellationError {
        // no-op
      } catch {
        setError(error)
      }

      isLoading = false
    }
  }

  func loadMoreComments() async {
    guard !isLoadingMoreComments,
          loadedCommentCount < allTopLevelCommentIds.count else { return }

    isLoadingMoreComments = true
    error = nil

    let nextIds = Array(allTopLevelCommentIds.dropFirst(loadedCommentCount).prefix(commentPageSize))
    do {
      let more = try await fetchCommentTree(ids: nextIds, depth: 0)
      comments.append(contentsOf: more)
      loadedCommentCount += commentPageSize
    } catch is CancellationError {
      // no-op
    } catch {
      setError(error)
    }

    isLoadingMoreComments = false
  }

  var hasMoreComments: Bool {
    loadedCommentCount < allTopLevelCommentIds.count
  }

  private func fetchCommentTree(ids: [Int], depth: Int) async throws -> [Comment] {
    let fetched = try await withThrowingTaskGroup(of: (Int, (Comment, [Comment])?).self) { group in
      for (index, id) in ids.enumerated() {
        group.addTask { [decoder] in
          try Task.checkCancellation()
          guard let url = URL(string: "\(baseURL)/item/\(id).json") else {
            return (index, nil)
          }
          let (data, _) = try await URLSession.shared.data(from: url)
          let item = try decoder.decode(HNItem.self, from: data)

          guard item.deleted != true, item.dead != true else { return (index, nil) }

          var parsedText: String?
          if let text = item.text {
            parsedText = Self.parseHTML(text)
          }

          let comment = Comment(from: item, parsedText: parsedText, depth: depth)

          var childComments = [Comment]()
          if depth < maxCommentDepth, let kids = item.kids, !kids.isEmpty {
            childComments = try await self.fetchCommentTree(ids: kids, depth: depth + 1)
          }

          return (index, (comment, childComments))
        }
      }

      var results = [(Int, (Comment, [Comment]))]()
      for try await result in group {
        if let pair = result.1 {
          results.append((result.0, pair))
        }
      }
      return results.sorted { $0.0 < $1.0 }
    }

    var flat = [Comment]()
    for (_, (comment, children)) in fetched {
      flat.append(comment)
      flat.append(contentsOf: children)
    }
    return flat
  }

  private func setError(_ error: any Error) {
    let message = error.localizedDescription
    if message.lowercased() == "cancelled" { return }
    if (error as? URLError)?.code == .cancelled { return }
    self.error = message
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
        // Escape markdown special chars in link text
        let escaped = text.replacingOccurrences(of: "[", with: "\\[")
          .replacingOccurrences(of: "]", with: "\\]")
        try link.text("\\m[" + escaped + "](" + href + ")\\m")
      }
      return try doc.text()
        .replacingOccurrences(of: "\\n", with: "\n")
        .replacingOccurrences(of: "\\m", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    } catch {
      return html
    }
  }
}
