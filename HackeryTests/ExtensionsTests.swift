//
//  ExtensionsTests.swift
//  HackeryTests
//
//  Created by Tim Shim on 30/3/26.
//  Copyright © 2026 Tim Shim. All rights reserved.
//

import Testing
import Foundation
@testable import Hackery

struct ExtensionsTests {

  // MARK: - Date.relativeTime

  @Test func relativeTimeForRecentDate() {
    let fiveMinutesAgo = Date().addingTimeInterval(-5 * 60)
    let result = fiveMinutesAgo.relativeTime
    #expect(result.contains("5"))
    #expect(result.contains("minute"))
  }

  @Test func relativeTimeForHoursAgo() {
    let twoHoursAgo = Date().addingTimeInterval(-2 * 3600)
    let result = twoHoursAgo.relativeTime
    #expect(result.contains("2"))
    #expect(result.contains("hour"))
  }

  @Test func relativeTimeForDaysAgo() {
    let threeDaysAgo = Date().addingTimeInterval(-3 * 86400)
    let result = threeDaysAgo.relativeTime
    #expect(result.contains("3"))
    #expect(result.contains("day"))
  }

  // MARK: - Date.relativeTimeShort

  @Test func relativeTimeShortIsAbbreviated() {
    let oneHourAgo = Date().addingTimeInterval(-3600)
    let short = oneHourAgo.relativeTimeShort
    let full = oneHourAgo.relativeTime

    // Short form should be shorter than full form
    #expect(short.count < full.count)
  }

  @Test func relativeTimeShortForMinutesAgo() {
    let tenMinutesAgo = Date().addingTimeInterval(-10 * 60)
    let result = tenMinutesAgo.relativeTimeShort
    // Abbreviated form should contain the number and be non-empty
    #expect(result.contains("10"))
    #expect(!result.isEmpty)
  }

  // MARK: - Story.timeAgo

  @Test func storyTimeAgoUsesRelativeTime() {
    let fiveMinutesAgo = Int(Date().timeIntervalSince1970) - 300
    let story = Story(storyId: 1, by: "user", descendants: 0, kids: [], score: 0, time: fiveMinutesAgo, title: "Test", type: "story", url: "", text: nil)

    #expect(story.timeAgo.contains("minute"))
  }

  // MARK: - Comment.timeAgo

  @Test func commentTimeAgoUsesRelativeTime() {
    let oneHourAgo = Int(Date().timeIntervalSince1970) - 3600
    let item = HNItem(id: 1, type: "comment", by: "user", time: oneHourAgo, text: "Hello", url: nil, title: nil, score: nil, descendants: nil, kids: nil, parent: 1, deleted: nil, dead: nil, poll: nil, parts: nil)
    let comment = Comment(from: item)

    #expect(comment.timeAgo.contains("hour"))
  }
}
