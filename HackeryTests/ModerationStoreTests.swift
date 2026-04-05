//
//  ModerationStoreTests.swift
//  HackeryTests
//
//  Created by Tim Shim on 31/3/26.
//  Copyright © 2026 Tim Shim. All rights reserved.
//

import Testing
import Foundation
import SwiftData
@testable import Hackery

@Suite(.serialized)
struct ModerationStoreTests {

  // MARK: - Helpers

  @MainActor
  private func makeStore() throws -> ModerationStore {
    let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
    let container = try ModelContainer(for: ModerationPreference.self, BlockedUser.self, configurations: config)
    return ModerationStore(modelContext: container.mainContext)
  }

  private func makeComment(id: Int = 1, by: String = "testuser", text: String = "Hello world") -> HNComment {
    let item = HNItem(id: id, type: "comment", by: by, time: 1700000000, text: text, url: nil, title: nil, score: nil, descendants: nil, kids: nil, parent: 0, deleted: false, dead: false, poll: nil, parts: nil)
    return HNComment(from: item, depth: 0)
  }

  /// Adds a blocked user to the store without going through modelContext.fetch
  @MainActor
  private func addBlockedUser(to store: ModerationStore, username: String, level: String) {
    let blocked = BlockedUser(username: username, blockLevel: level)
    store.blockedUsers.append(blocked)
  }

  // MARK: - shouldHideComment

  @MainActor @Test func shouldHideReturnsFalseWhenModerationOff() throws {
    let store = try makeStore()
    let comment = makeComment()
    #expect(!store.shouldHideComment(comment))
  }

  @MainActor @Test func shouldHideReturnsTrueWhenFlaggedAndHideOnce() throws {
    let store = try makeStore()
    let comment = makeComment()
    store.flaggedCommentIds.insert(comment.id)
    store.hideOnce = true
    #expect(store.shouldHideComment(comment))
  }

  @MainActor @Test func shouldHideReturnsTrueWhenFlaggedAndHideAlways() throws {
    let store = try makeStore()
    let comment = makeComment()
    store.flaggedCommentIds.insert(comment.id)
    store.hideAlways = true
    #expect(store.shouldHideComment(comment))
  }

  @MainActor @Test func shouldHideReturnsFalseAfterUnhide() throws {
    let store = try makeStore()
    let comment = makeComment()
    store.flaggedCommentIds.insert(comment.id)
    store.hideOnce = true
    #expect(store.shouldHideComment(comment))

    store.unhideComment(comment.id)
    #expect(!store.shouldHideComment(comment))
  }

  // MARK: - Blocked Users

  @MainActor @Test func shouldHideReturnsTrueForHideLevelBlockedUser() throws {
    let store = try makeStore()
    let comment = makeComment(by: "baduser")
    addBlockedUser(to: store, username: "baduser", level: "hide")
    #expect(store.shouldHideComment(comment))
  }

  @MainActor @Test func shouldHideReturnsFalseForHideBlockedUserAfterUnhide() throws {
    let store = try makeStore()
    let comment = makeComment(by: "baduser")
    addBlockedUser(to: store, username: "baduser", level: "hide")
    #expect(store.shouldHideComment(comment))

    store.unhideComment(comment.id)
    #expect(!store.shouldHideComment(comment))
  }

  @MainActor @Test func shouldHideReturnsTrueForRemoveLevelBlockedUser() throws {
    let store = try makeStore()
    let comment = makeComment(by: "baduser")
    addBlockedUser(to: store, username: "baduser", level: "remove")
    #expect(store.shouldRemoveComment(comment))
  }

  @MainActor @Test func removeBlockedUserCannotBeUnhidden() throws {
    let store = try makeStore()
    let comment = makeComment(by: "baduser")
    addBlockedUser(to: store, username: "baduser", level: "remove")
    store.unhideComment(comment.id)
    // Still removed even after unhide attempt
    #expect(store.shouldRemoveComment(comment))
  }

  // MARK: - canUnhide

  @MainActor @Test func canUnhideReturnsTrueForHideLevel() throws {
    let store = try makeStore()
    let comment = makeComment(by: "baduser")
    addBlockedUser(to: store, username: "baduser", level: "hide")
    #expect(store.canUnhide(comment))
  }

  @MainActor @Test func canUnhideReturnsFalseForRemoveLevel() throws {
    let store = try makeStore()
    let comment = makeComment(by: "baduser")
    addBlockedUser(to: store, username: "baduser", level: "remove")
    #expect(!store.canUnhide(comment))
  }

  @MainActor @Test func canUnhideReturnsTrueForNonBlockedUser() throws {
    let store = try makeStore()
    let comment = makeComment()
    #expect(store.canUnhide(comment))
  }

  // MARK: - resetSession

  @MainActor @Test func resetSessionClearsSessionState() throws {
    let store = try makeStore()
    store.hideOnce = true
    store.flaggedCommentIds = [1, 2, 3]
    store.manuallyUnhiddenCommentIds = [1]

    store.resetSession()

    #expect(!store.hideOnce)
    #expect(store.flaggedCommentIds.isEmpty)
    #expect(store.manuallyUnhiddenCommentIds.isEmpty)
  }

  @MainActor @Test func resetSessionPreservesPersistedState() throws {
    let store = try makeStore()
    store.hideAlways = true
    addBlockedUser(to: store, username: "blocked", level: "hide")

    store.resetSession()

    #expect(store.hideAlways)
    #expect(store.isBlocked("blocked"))
  }

  // MARK: - Model Defaults

  @MainActor @Test func blockedUserModelDefaults() throws {
    let blocked = BlockedUser(username: "user1", blockLevel: "hide")
    #expect(blocked.username == "user1")
    #expect(blocked.blockLevel == "hide")
    #expect(blocked.blockedAt <= Date())
  }

  @MainActor @Test func moderationPreferenceDefaults() throws {
    let store = try makeStore()
    #expect(!store.hideAlways)
  }

  // MARK: - isModerationActive

  @MainActor @Test func isModerationActiveWhenHideOnce() throws {
    let store = try makeStore()
    store.hideOnce = true
    #expect(store.isModerationActive)
  }

  @MainActor @Test func isModerationActiveWhenHideAlways() throws {
    let store = try makeStore()
    store.hideAlways = true
    #expect(store.isModerationActive)
  }

  @MainActor @Test func isModerationInactiveByDefault() throws {
    let store = try makeStore()
    #expect(!store.isModerationActive)
  }

  // MARK: - Block User Updates

  @MainActor @Test func blockUserUpgradesLevel() throws {
    let store = try makeStore()
    addBlockedUser(to: store, username: "user1", level: "hide")
    #expect(store.blockLevel(for: "user1") == "hide")

    // Simulate upgrade by modifying the existing entry
    store.blockedUsers.first { $0.username == "user1" }?.blockLevel = "remove"
    #expect(store.blockLevel(for: "user1") == "remove")
  }

  // MARK: - Sensitivity Level

  @MainActor @Test func sensitivityLevelDefaultsToFive() throws {
    let store = try makeStore()
    #expect(store.sensitivityLevel == 5)
  }

  @MainActor @Test func sensitivityLevelIsSessionOnly() throws {
    let store = try makeStore()
    store.sensitivityLevel = 8
    #expect(store.sensitivityLevel == 8)

    let store2 = try makeStore()
    #expect(store2.sensitivityLevel == 5)
  }
}

// MARK: - CommentClassifier Prompt Tests

struct CommentClassifierTests {

  @Test func buildPromptReturnsNilAtSensitivityZero() {
    let prompt = CommentClassifier.buildPrompt(for: "some text", sensitivityLevel: 0)
    #expect(prompt == nil)
  }

  @Test func buildPromptReturnsPromptAtSensitivityOne() {
    let prompt = CommentClassifier.buildPrompt(for: "some text", sensitivityLevel: 1)
    #expect(prompt != nil)
    #expect(prompt!.contains("some text"))
  }

  @Test func buildPromptLenientAtLowSensitivity() {
    let prompt = CommentClassifier.buildPrompt(for: "hello", sensitivityLevel: 1)!
    #expect(prompt.contains("extremely offensive"))
    #expect(prompt.contains("should NOT be flagged"))
  }

  @Test func buildPromptModerateLowSensitivity() {
    let prompt = CommentClassifier.buildPrompt(for: "hello", sensitivityLevel: 3)!
    #expect(prompt.contains("clearly offensive or hateful"))
  }

  @Test func buildPromptModerateAtMidSensitivity() {
    let prompt = CommentClassifier.buildPrompt(for: "hello", sensitivityLevel: 5)!
    #expect(prompt.contains("offensive, toxic, hateful"))
    #expect(prompt.contains("Do not flag"))
  }

  @Test func buildPromptStrictAtHighSensitivity() {
    let prompt = CommentClassifier.buildPrompt(for: "hello", sensitivityLevel: 7)!
    #expect(prompt.contains("passive-aggressive"))
    #expect(prompt.contains("mildly hostile"))
  }

  @Test func buildPromptReturnsNilAtNine() {
    // Level 9 uses banned word list, not AI prompt
    let prompt = CommentClassifier.buildPrompt(for: "hello", sensitivityLevel: 9)
    #expect(prompt == nil)
  }

  @Test func buildPromptIncludesCommentText() {
    let text = "This is a unique test comment 12345"
    for level in 1...8 {
      let prompt = CommentClassifier.buildPrompt(for: text, sensitivityLevel: level)!
      #expect(prompt.contains(text))
    }
  }

  @Test func buildPromptSensitivityRangesAreContinuous() {
    // Every level 1-8 should produce a non-nil prompt
    for level in 1...8 {
      let prompt = CommentClassifier.buildPrompt(for: "test", sensitivityLevel: level)
      #expect(prompt != nil, "Level \(level) should produce a prompt")
    }
  }

  // MARK: - Banned Word List (Sensitivity 9)

  @Test func bannedWordDetectsObviousProfanity() {
    #expect(CommentClassifier.containsBannedWord("This is fucking ridiculous"))
    #expect(CommentClassifier.containsBannedWord("What a shitty take"))
    #expect(CommentClassifier.containsBannedWord("You're an idiot"))
  }

  @Test func bannedWordDetectsNegativeWords() {
    #expect(CommentClassifier.containsBannedWord("This will never work"))
    #expect(CommentClassifier.containsBannedWord("I can't believe this"))
    #expect(CommentClassifier.containsBannedWord("That's just wrong"))
  }

  @Test func bannedWordDetectsHostility() {
    #expect(CommentClassifier.containsBannedWord("You're pathetic"))
    #expect(CommentClassifier.containsBannedWord("What a loser"))
    #expect(CommentClassifier.containsBannedWord("This is garbage"))
  }

  @Test func bannedWordDetectsMultiWordPhrases() {
    #expect(CommentClassifier.containsBannedWord("Oh shut up already"))
    #expect(CommentClassifier.containsBannedWord("Honestly nobody cares about this"))
  }

  @Test func bannedWordIsCaseInsensitive() {
    #expect(CommentClassifier.containsBannedWord("SHUT UP"))
    #expect(CommentClassifier.containsBannedWord("You're an IDIOT"))
    #expect(CommentClassifier.containsBannedWord("This SUCKS"))
  }

  @Test func bannedWordDoesNotFalsePositiveOnSubstrings() {
    // "ass" shouldn't match "class" or "assessment"
    #expect(!CommentClassifier.containsBannedWord("This is a great class"))
    #expect(!CommentClassifier.containsBannedWord("The assessment was thorough"))
  }

  @Test func bannedWordAllowsCleanText() {
    #expect(!CommentClassifier.containsBannedWord("Great article, thanks for sharing"))
    #expect(!CommentClassifier.containsBannedWord("I learned a lot from this"))
    #expect(!CommentClassifier.containsBannedWord("Interesting perspective on the topic"))
  }
}
