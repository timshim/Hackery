//
//  FeedViewModelTests.swift
//  HackeryTests
//
//  Created by Tim Shim on 30/3/26.
//  Copyright © 2026 Tim Shim. All rights reserved.
//

import Testing
import Foundation
@testable import Hackery

// MARK: - URL Protocol Stub

private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
  nonisolated(unsafe) static var responseData: [String: Data] = [:]
  nonisolated(unsafe) static var responseErrors: [String: Error] = [:]

  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    let urlString = request.url?.absoluteString ?? ""

    if let error = Self.responseErrors[urlString] {
      client?.urlProtocol(self, didFailWithError: error)
      return
    }

    let data = Self.responseData[urlString] ?? Data()
    let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    client?.urlProtocol(self, didLoad: data)
    client?.urlProtocolDidFinishLoading(self)
  }

  override func stopLoading() {}
}

// MARK: - Helpers

private let baseURL = "https://hacker-news.firebaseio.com/v0"

private func makeItem(id: Int, title: String = "Test", url: String = "https://example.com", score: Int = 10, by: String = "user", descendants: Int = 0, kids: [Int] = [], text: String? = nil, type: String = "story") -> Data {
  var dict: [String: Any] = [
    "id": id,
    "title": title,
    "url": url,
    "score": score,
    "by": by,
    "descendants": descendants,
    "kids": kids,
    "type": type,
  ]
  if let text { dict["text"] = text }
  return try! JSONSerialization.data(withJSONObject: dict)
}

private func makeCommentItem(id: Int, by: String = "commenter", text: String = "A comment", parent: Int = 1, kids: [Int] = [], deleted: Bool = false, dead: Bool = false) -> Data {
  let dict: [String: Any] = [
    "id": id,
    "by": by,
    "text": text,
    "parent": parent,
    "kids": kids,
    "type": "comment",
    "deleted": deleted,
    "dead": dead,
  ]
  return try! JSONSerialization.data(withJSONObject: dict)
}

private func stubStoryIds(_ ids: [Int]) {
  let data = try! JSONSerialization.data(withJSONObject: ids)
  StubURLProtocol.responseData["\(baseURL)/topstories.json"] = data
}

private func stubItem(id: Int, data: Data) {
  StubURLProtocol.responseData["\(baseURL)/item/\(id).json"] = data
}

// MARK: - Tests

@Suite(.serialized)
struct FeedViewModelTests {

  init() {
    StubURLProtocol.responseData.removeAll()
    StubURLProtocol.responseErrors.removeAll()
    URLProtocol.registerClass(StubURLProtocol.self)
  }

  // MARK: - loadTopStories

  @Test func loadTopStoriesFetchesFirstPage() async {
    stubStoryIds([1, 2, 3])
    stubItem(id: 1, data: makeItem(id: 1, title: "Story One"))
    stubItem(id: 2, data: makeItem(id: 2, title: "Story Two"))
    stubItem(id: 3, data: makeItem(id: 3, title: "Story Three"))

    let vm = await FeedViewModel()
    await vm.loadTopStories()

    // Wait for internal Task to finish
    try? await Task.sleep(for: .milliseconds(200))

    let stories = await vm.stories
    #expect(stories.count == 3)
    #expect(stories[0].title == "Story One")
    #expect(stories[1].title == "Story Two")
    #expect(stories[2].title == "Story Three")

    let isLoading = await vm.isLoading
    #expect(isLoading == false)
  }

  @Test func loadTopStoriesSetsLoadingState() async {
    stubStoryIds([])

    let vm = await FeedViewModel()
    await vm.loadTopStories()
    try? await Task.sleep(for: .milliseconds(100))

    let isLoading = await vm.isLoading
    #expect(isLoading == false)
  }

  @Test func loadTopStoriesFiltersDeletedAndDead() async {
    stubStoryIds([1, 2, 3])
    stubItem(id: 1, data: makeItem(id: 1, title: "Alive"))

    // Deleted story
    let deletedDict: [String: Any] = ["id": 2, "deleted": true, "type": "story", "title": "Deleted"]
    stubItem(id: 2, data: try! JSONSerialization.data(withJSONObject: deletedDict))

    // Dead story
    let deadDict: [String: Any] = ["id": 3, "dead": true, "type": "story", "title": "Dead"]
    stubItem(id: 3, data: try! JSONSerialization.data(withJSONObject: deadDict))

    let vm = await FeedViewModel()
    await vm.loadTopStories()
    try? await Task.sleep(for: .milliseconds(200))

    let stories = await vm.stories
    #expect(stories.count == 1)
    #expect(stories[0].title == "Alive")
  }

  @Test func refreshClearsExistingStories() async {
    stubStoryIds([1])
    stubItem(id: 1, data: makeItem(id: 1, title: "New Story"))

    let vm = await FeedViewModel()

    // Load initial stories
    await vm.loadTopStories()
    try? await Task.sleep(for: .milliseconds(200))

    // Refresh
    await vm.loadTopStories(refresh: true)
    try? await Task.sleep(for: .milliseconds(200))

    let stories = await vm.stories
    #expect(stories.count == 1)
    #expect(stories[0].title == "New Story")
  }

  @Test func loadTopStoriesSetsErrorOnFailure() async {
    // Stub a bad URL response by not registering any data (will return empty data, which can't decode as [Int])
    StubURLProtocol.responseErrors["\(baseURL)/topstories.json"] = URLError(.badServerResponse)

    let vm = await FeedViewModel()
    await vm.loadTopStories()
    try? await Task.sleep(for: .milliseconds(200))

    let error = await vm.error
    #expect(error != nil)

    let isLoading = await vm.isLoading
    #expect(isLoading == false)
  }

  // MARK: - loadMoreStories

  @Test func loadMoreStoriesPaginates() async {
    // Create 30 story IDs (page size is 25)
    let ids = Array(1...30)
    stubStoryIds(ids)
    for id in ids {
      stubItem(id: id, data: makeItem(id: id, title: "Story \(id)"))
    }

    let vm = await FeedViewModel()
    await vm.loadTopStories()
    try? await Task.sleep(for: .milliseconds(300))

    let firstPageCount = await vm.stories.count
    #expect(firstPageCount == 25)

    let hasMore = await vm.hasMoreStories
    #expect(hasMore == true)

    await vm.loadMoreStories()

    let totalCount = await vm.stories.count
    #expect(totalCount == 30)

    let hasMoreAfter = await vm.hasMoreStories
    #expect(hasMoreAfter == false)
  }

  @Test func loadMoreStoriesNoOpWhenNothingLeft() async {
    stubStoryIds([1])
    stubItem(id: 1, data: makeItem(id: 1, title: "Only"))

    let vm = await FeedViewModel()
    await vm.loadTopStories()
    try? await Task.sleep(for: .milliseconds(200))

    let hasMore = await vm.hasMoreStories
    #expect(hasMore == false)

    await vm.loadMoreStories()
    let count = await vm.stories.count
    #expect(count == 1)
  }

  // MARK: - loadComments

  @Test func loadCommentsFlattensTree() async {
    let story = await makeStory(kids: [10, 11])

    stubItem(id: 10, data: makeCommentItem(id: 10, text: "Top comment", kids: [20]))
    stubItem(id: 11, data: makeCommentItem(id: 11, text: "Second top"))
    stubItem(id: 20, data: makeCommentItem(id: 20, text: "Reply", parent: 10))

    let vm = await FeedViewModel()
    await vm.loadComments(for: story)
    try? await Task.sleep(for: .milliseconds(300))

    let comments = await vm.comments
    #expect(comments.count == 3)

    let isLoading = await vm.isLoading
    #expect(isLoading == false)
  }

  @Test func loadCommentsFiltersDeletedComments() async {
    let story = await makeStory(kids: [10, 11])

    stubItem(id: 10, data: makeCommentItem(id: 10, text: "Visible"))
    stubItem(id: 11, data: makeCommentItem(id: 11, deleted: true))

    let vm = await FeedViewModel()
    await vm.loadComments(for: story)
    try? await Task.sleep(for: .milliseconds(200))

    let comments = await vm.comments
    #expect(comments.count == 1)
    #expect(comments.first?.text == "Visible")
  }

  @Test func loadCommentsParsesHTML() async {
    let story = await makeStory(kids: [10])

    stubItem(id: 10, data: makeCommentItem(id: 10, text: "<p>Hello &amp; world</p>"))

    let vm = await FeedViewModel()
    await vm.loadComments(for: story)
    try? await Task.sleep(for: .milliseconds(200))

    let comments = await vm.comments
    #expect(comments.first?.text == "Hello & world")
  }

  @Test func hasMoreCommentsReflectsPagination() async {
    // commentPageSize is 3, so 5 kids means there's more
    let story = await makeStory(kids: [10, 11, 12, 13, 14])

    for id in 10...14 {
      stubItem(id: id, data: makeCommentItem(id: id, text: "Comment \(id)"))
    }

    let vm = await FeedViewModel()
    await vm.loadComments(for: story)
    try? await Task.sleep(for: .milliseconds(200))

    let hasMore = await vm.hasMoreComments
    #expect(hasMore == true)

    let count = await vm.comments.count
    #expect(count == 3)

    await vm.loadMoreComments()

    let totalCount = await vm.comments.count
    #expect(totalCount == 5)

    let hasMoreAfter = await vm.hasMoreComments
    #expect(hasMoreAfter == false)
  }

  // MARK: - Model Tests

  @Test func storyInitFromHNItemDecodesEntities() {
    let item = HNItem(id: 1, type: "story", by: "author", time: 1000, text: nil, url: "https://example.com", title: "Tom &amp; Jerry", score: 42, descendants: 5, kids: [10, 20], parent: nil, deleted: nil, dead: nil, poll: nil, parts: nil)
    let story = Story(from: item)

    #expect(story.title == "Tom & Jerry")
    #expect(story.by == "author")
    #expect(story.score == 42)
    #expect(story.descendants == 5)
    #expect(story.kids == [10, 20])
  }

  @Test func storyInitFromHNItemDefaultsMissingFields() {
    let item = HNItem(id: 99, type: nil, by: nil, time: nil, text: nil, url: nil, title: nil, score: nil, descendants: nil, kids: nil, parent: nil, deleted: nil, dead: nil, poll: nil, parts: nil)
    let story = Story(from: item)

    #expect(story.id == 99)
    #expect(story.by == "[deleted]")
    #expect(story.title == "")
    #expect(story.url == "")
    #expect(story.score == 0)
    #expect(story.descendants == 0)
    #expect(story.kids.isEmpty)
    #expect(story.type == "story")
  }

  @Test func commentInitFromHNItem() {
    let item = HNItem(id: 50, type: "comment", by: "commenter", time: 2000, text: "Hello", url: nil, title: nil, score: nil, descendants: nil, kids: [60], parent: 1, deleted: nil, dead: nil, poll: nil, parts: nil)
    let comment = Comment(from: item, depth: 2)

    #expect(comment.id == 50)
    #expect(comment.by == "commenter")
    #expect(comment.text == "Hello")
    #expect(comment.depth == 2)
    #expect(comment.kids == [60])
    #expect(comment.parent == 1)
    #expect(comment.deleted == false)
    #expect(comment.dead == false)
  }

  @Test func commentInitUsesParsedTextOverRaw() {
    let item = HNItem(id: 50, type: "comment", by: "user", time: 2000, text: "<p>raw</p>", url: nil, title: nil, score: nil, descendants: nil, kids: nil, parent: 1, deleted: nil, dead: nil, poll: nil, parts: nil)
    let comment = Comment(from: item, parsedText: "parsed")

    #expect(comment.text == "parsed")
  }

  @Test func commentInitFallsBackToRemoved() {
    let item = HNItem(id: 50, type: "comment", by: nil, time: nil, text: nil, url: nil, title: nil, score: nil, descendants: nil, kids: nil, parent: nil, deleted: true, dead: nil, poll: nil, parts: nil)
    let comment = Comment(from: item)

    #expect(comment.text == "[removed]")
    #expect(comment.deleted == true)
  }

  // MARK: - Helpers

  @MainActor
  private func makeStory(kids: [Int]) -> Story {
    Story(storyId: 1, by: "author", descendants: kids.count, kids: kids, score: 100, time: Int(Date().timeIntervalSince1970), title: "Test Story", type: "story", url: "https://example.com", text: nil)
  }
}
