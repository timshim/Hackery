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

// MARK: - Model Unit Tests

@Suite
struct FeedModelTests {

  // MARK: - Story

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

  // MARK: - Comment

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
}
