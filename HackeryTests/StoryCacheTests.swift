//
//  StoryCacheTests.swift
//  HackeryTests
//
//  Created by Tim Shim on 30/3/26.
//  Copyright © 2026 Tim Shim. All rights reserved.
//

import Testing
import Foundation
@testable import Hackery

@Suite(.serialized)
struct StoryCacheTests {

  init() {
    StoryCache.clear()
  }

  // MARK: - Helpers

  private func makeStory(id: Int, title: String = "Test") -> Story {
    Story(storyId: id, by: "user", descendants: 0, kids: [], score: 10, time: Int(Date().timeIntervalSince1970), title: title, type: "story", url: "https://example.com", text: nil)
  }

  // MARK: - Save and Load

  @Test func saveAndLoadRoundTrip() {
    let stories = [makeStory(id: 1, title: "First"), makeStory(id: 2, title: "Second")]
    StoryCache.save(stories)

    let loaded = StoryCache.load()
    #expect(loaded != nil)
    #expect(loaded?.count == 2)
    #expect(loaded?[0].title == "First")
    #expect(loaded?[1].title == "Second")
  }

  @Test func loadReturnsNilWhenEmpty() {
    let loaded = StoryCache.load()
    #expect(loaded == nil)
  }

  @Test func clearRemovesCache() {
    StoryCache.save([makeStory(id: 1)])
    StoryCache.clear()

    let loaded = StoryCache.load()
    #expect(loaded == nil)
  }

  @Test func saveOverwritesPreviousCache() {
    StoryCache.save([makeStory(id: 1, title: "Old")])
    StoryCache.save([makeStory(id: 2, title: "New")])

    let loaded = StoryCache.load()
    #expect(loaded?.count == 1)
    #expect(loaded?[0].title == "New")
  }

  @Test func loadReturnsNilWhenExpired() {
    StoryCache.save([makeStory(id: 1)])

    // Manually set timestamp to 31 minutes ago
    let expiredTimestamp = Date().timeIntervalSince1970 - (31 * 60)
    UserDefaults.standard.set(expiredTimestamp, forKey: "cachedStoriesTimestamp")

    let loaded = StoryCache.load()
    #expect(loaded == nil)
  }

  @Test func loadSucceedsWhenNotYetExpired() {
    StoryCache.save([makeStory(id: 1)])

    // Set timestamp to 29 minutes ago (within 30-minute window)
    let recentTimestamp = Date().timeIntervalSince1970 - (29 * 60)
    UserDefaults.standard.set(recentTimestamp, forKey: "cachedStoriesTimestamp")

    let loaded = StoryCache.load()
    #expect(loaded != nil)
    #expect(loaded?.count == 1)
  }

  @Test func preservesAllStoryFields() throws {
    let story = Story(storyId: 42, by: "author", descendants: 5, kids: [10, 20], score: 100, time: 1700000000, title: "Full Story", type: "story", url: "https://example.com/full", text: "Some text")
    StoryCache.save([story])

    let stories = try #require(StoryCache.load())
    let loaded = try #require(stories.first)
    #expect(loaded.id == 42)
    #expect(loaded.by == "author")
    #expect(loaded.descendants == 5)
    #expect(loaded.kids == [10, 20])
    #expect(loaded.score == 100)
    #expect(loaded.time == 1700000000)
    #expect(loaded.title == "Full Story")
    #expect(loaded.type == "story")
    #expect(loaded.url == "https://example.com/full")
    #expect(loaded.text == "Some text")
  }
}
