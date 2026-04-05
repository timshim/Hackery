//
//  EngagementTrackerTests.swift
//  HackeryTests
//
//  Created by Tim Shim on 4/5/26.
//  Copyright © 2026 Tim Shim. All rights reserved.
//

import Testing
import Foundation
@testable import Hackery

@Suite(.serialized)
struct EngagementTrackerTests {

  init() {
    // Clear all engagement keys before each test
    let keys = [
      "engagementInteractionCount",
      "engagementSinceLastPrompt",
      "engagementHasShownReview",
      "engagementTipCount",
      "engagementCurrentInterval",
      "engagementPhase"
    ]
    for key in keys {
      UserDefaults.standard.removeObject(forKey: key)
    }
  }

  // MARK: - Helpers

  /// Records n interactions then checks for prompt.
  @MainActor private func record(_ n: Int, on tracker: EngagementTracker) {
    for _ in 1...n { tracker.recordInteraction() }
    tracker.checkForPrompt()
  }

  // MARK: - Initial State

  @MainActor @Test func initialStateHasNoPendingPrompt() {
    let tracker = EngagementTracker()
    #expect(tracker.pendingPrompt == nil)
  }

  // MARK: - Review Prompt at Threshold

  @MainActor @Test func reviewPromptAtThreshold() {
    let tracker = EngagementTracker()
    // Record one less than threshold
    tracker.recordInteraction()
    tracker.checkForPrompt()
    #expect(tracker.pendingPrompt == nil)

    // Hit threshold
    tracker.recordInteraction()
    tracker.checkForPrompt()
    #expect(tracker.pendingPrompt == .review)
  }

  @MainActor @Test func noReviewBeforeThreshold() {
    let tracker = EngagementTracker()
    tracker.recordInteraction() // 1 interaction, threshold is 2
    tracker.checkForPrompt()
    #expect(tracker.pendingPrompt == nil)
  }

  // MARK: - Tip Jar Schedule After Review

  @MainActor @Test func tipJarAt30AfterReview() {
    let tracker = EngagementTracker()
    record(2, on: tracker)
    #expect(tracker.pendingPrompt == .review)
    tracker.promptShown()

    // Next 29 interactions: no prompt
    record(29, on: tracker)
    #expect(tracker.pendingPrompt == nil)

    // 30th interaction after review
    record(1, on: tracker)
    #expect(tracker.pendingPrompt == .tipJar)
  }

  @MainActor @Test func tipJarAt50AfterFirst() {
    let tracker = EngagementTracker()
    // Review at 15
    record(15, on: tracker)
    tracker.promptShown()

    // Tip jar at 30
    record(30, on: tracker)
    tracker.promptShown()

    // Next 49: no prompt
    record(49, on: tracker)
    #expect(tracker.pendingPrompt == nil)

    // 50th
    record(1, on: tracker)
    #expect(tracker.pendingPrompt == .tipJar)
  }

  @MainActor @Test func recurringEvery50AfterSchedule() {
    let tracker = EngagementTracker()
    // Review at 15
    record(15, on: tracker)
    tracker.promptShown()

    // Tip at 30
    record(30, on: tracker)
    tracker.promptShown()

    // Tip at 50
    record(50, on: tracker)
    tracker.promptShown()

    // Recurring: next tip at 50
    record(49, on: tracker)
    #expect(tracker.pendingPrompt == nil)
    record(1, on: tracker)
    #expect(tracker.pendingPrompt == .tipJar)

    // Dismiss, another 50
    tracker.promptShown()
    record(50, on: tracker)
    #expect(tracker.pendingPrompt == .tipJar)
  }

  // MARK: - Post-Tip Behavior

  @MainActor @Test func afterFirstTipIntervalIs300() {
    let tracker = EngagementTracker()
    // Review at 15
    record(15, on: tracker)
    tracker.promptShown()

    // Tip jar at 30
    record(30, on: tracker)
    tracker.promptShown()

    // Simulate tip
    tracker.recordTip()

    // 299 interactions: no prompt
    record(299, on: tracker)
    #expect(tracker.pendingPrompt == nil)

    // 300th
    record(1, on: tracker)
    #expect(tracker.pendingPrompt == .tipJar)
  }

  @MainActor @Test func afterSecondTipIntervalDoubles() {
    let tracker = EngagementTracker()
    // Skip to post-tip state
    tracker.recordTip()

    // First 300
    record(300, on: tracker)
    #expect(tracker.pendingPrompt == .tipJar)
    tracker.promptShown()

    // Tip again
    tracker.recordTip()

    // Now interval should be 600
    record(599, on: tracker)
    #expect(tracker.pendingPrompt == nil)
    record(1, on: tracker)
    #expect(tracker.pendingPrompt == .tipJar)
  }

  @MainActor @Test func afterThirdTipIntervalDoublesAgain() {
    let tracker = EngagementTracker()
    tracker.recordTip()   // tipCount=1, interval=300
    tracker.recordTip()   // tipCount=2, interval=600
    tracker.recordTip()   // tipCount=3, interval=1200

    record(1199, on: tracker)
    #expect(tracker.pendingPrompt == nil)
    record(1, on: tracker)
    #expect(tracker.pendingPrompt == .tipJar)
  }

  // MARK: - Post-Tip Without Tipping Again

  @MainActor @Test func dismissedTipJarStillUsesCurrentInterval() {
    let tracker = EngagementTracker()
    tracker.recordTip() // tipCount=1, interval=300

    record(300, on: tracker)
    #expect(tracker.pendingPrompt == .tipJar)
    tracker.promptShown() // dismissed without tipping

    // Still 300 interval since tipCount didn't change
    record(299, on: tracker)
    #expect(tracker.pendingPrompt == nil)
    record(1, on: tracker)
    #expect(tracker.pendingPrompt == .tipJar)
  }

  // MARK: - promptShown

  @MainActor @Test func promptShownResetsCounter() {
    let tracker = EngagementTracker()
    record(2, on: tracker)
    #expect(tracker.pendingPrompt == .review)

    tracker.promptShown()
    #expect(tracker.pendingPrompt == nil)
    #expect(UserDefaults.standard.integer(forKey: "engagementSinceLastPrompt") == 0)
  }

  @MainActor @Test func promptShownWithNoPromptIsNoop() {
    let tracker = EngagementTracker()
    tracker.promptShown()
    #expect(tracker.pendingPrompt == nil)
  }

  // MARK: - Prompt Equatable

  @Test func promptEquatable() {
    #expect(EngagementTracker.Prompt.review == .review)
    #expect(EngagementTracker.Prompt.tipJar == .tipJar)
    #expect(EngagementTracker.Prompt.review != .tipJar)
  }

  // MARK: - Persistence Across Instances

  @MainActor @Test func statePersistedAcrossInstances() {
    let tracker1 = EngagementTracker()
    tracker1.recordInteraction() // 1 interaction

    let tracker2 = EngagementTracker()
    tracker2.recordInteraction() // 2nd interaction total
    tracker2.checkForPrompt()
    #expect(tracker2.pendingPrompt == .review) // threshold reached
  }

  // MARK: - checkForPrompt

  @MainActor @Test func checkForPromptSetsPromptWithoutRecording() {
    let tracker = EngagementTracker()
    for _ in 1...2 { tracker.recordInteraction() }
    #expect(tracker.pendingPrompt == nil) // recordInteraction no longer sets it

    tracker.checkForPrompt()
    #expect(tracker.pendingPrompt == .review)
  }
}
