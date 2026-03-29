//
//  BookmarkStoreTests.swift
//  HackeryTests
//
//  Created by Tim Shim on 30/3/26.
//  Copyright © 2026 Tim Shim. All rights reserved.
//

import Testing
import Foundation
@testable import Hackery

struct BookmarkStoreTests {

  // MARK: - BookmarkedStory round-trip

  private func makeStory(id: Int = 1, title: String = "Test", text: String? = nil) -> Story {
    Story(storyId: id, by: "author", descendants: 5, kids: [10, 20], score: 42, time: 1700000000, title: title, type: "story", url: "https://example.com", text: text)
  }

  @Test func bookmarkedStoryInitCopiesAllFields() {
    let story = makeStory(title: "Bookmarked", text: "Body text")
    let bookmarked = BookmarkedStory(from: story)

    #expect(bookmarked.storyId == 1)
    #expect(bookmarked.by == "author")
    #expect(bookmarked.descendants == 5)
    #expect(bookmarked.kids == [10, 20])
    #expect(bookmarked.score == 42)
    #expect(bookmarked.time == 1700000000)
    #expect(bookmarked.title == "Bookmarked")
    #expect(bookmarked.type == "story")
    #expect(bookmarked.url == "https://example.com")
    #expect(bookmarked.text == "Body text")
  }

  @Test func toStoryRoundTrip() {
    let original = makeStory(id: 99, title: "Round Trip", text: "Content")
    let bookmarked = BookmarkedStory(from: original)
    let restored = bookmarked.toStory()

    #expect(restored.id == original.id)
    #expect(restored.by == original.by)
    #expect(restored.descendants == original.descendants)
    #expect(restored.kids == original.kids)
    #expect(restored.score == original.score)
    #expect(restored.time == original.time)
    #expect(restored.title == original.title)
    #expect(restored.type == original.type)
    #expect(restored.url == original.url)
    #expect(restored.text == original.text)
  }

  @Test func toStoryHandlesNilText() {
    let story = makeStory(text: nil)
    let bookmarked = BookmarkedStory(from: story)
    let restored = bookmarked.toStory()

    #expect(restored.text == nil)
  }

  @Test func bookmarkedAtIsSetToNow() {
    let before = Date()
    let bookmarked = BookmarkedStory(from: makeStory())
    let after = Date()

    #expect(bookmarked.bookmarkedAt >= before)
    #expect(bookmarked.bookmarkedAt <= after)
  }

  // MARK: - Story Codable

  @Test func storyCodableRoundTrip() throws {
    let story = Story(storyId: 7, by: "coder", descendants: 3, kids: [100], score: 50, time: 1700000000, title: "Codable Test", type: "story", url: "https://test.com", text: "Body")

    let data = try JSONEncoder().encode(story)
    let decoded = try JSONDecoder().decode(Story.self, from: data)

    #expect(decoded.id == story.id)
    #expect(decoded.by == story.by)
    #expect(decoded.descendants == story.descendants)
    #expect(decoded.kids == story.kids)
    #expect(decoded.score == story.score)
    #expect(decoded.time == story.time)
    #expect(decoded.title == story.title)
    #expect(decoded.type == story.type)
    #expect(decoded.url == story.url)
    #expect(decoded.text == story.text)
  }

  @Test func storyHashableConformance() {
    let story1 = makeStory(id: 1, title: "A")
    let story2 = makeStory(id: 2, title: "B")
    let story1Dup = makeStory(id: 1, title: "A")

    var set = Set<Story>()
    set.insert(story1)
    set.insert(story2)
    set.insert(story1Dup)

    #expect(set.count == 2)
  }
}
