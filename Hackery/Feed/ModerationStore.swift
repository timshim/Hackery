//
//  ModerationStore.swift
//  Hackery
//
//  Created by Tim Shim on 31/3/26.
//  Copyright © 2026 Tim Shim. All rights reserved.
//

import SwiftUI
import SwiftData
import CoreData

// MARK: - SwiftData Models

@Model
final class ModerationPreference {
  var hideAlways: Bool = false
  var identifier: String = "default"
  var sensitivityLevel: Int = 5

  init(hideAlways: Bool = false, sensitivityLevel: Int = 5) {
    self.hideAlways = hideAlways
    self.identifier = "default"
    self.sensitivityLevel = sensitivityLevel
  }
}

@Model
final class BlockedUser {
  var username: String = ""
  var blockedAt: Date = Date.distantPast
  /// "hide" = comments hidden but can be individually unhidden
  /// "remove" = comments permanently removed, cannot unhide
  var blockLevel: String = "hide"

  init(username: String, blockLevel: String = "hide") {
    self.username = username
    self.blockedAt = Date()
    self.blockLevel = blockLevel
  }
}

// MARK: - ModerationStore

@MainActor
@Observable
final class ModerationStore {
  private var modelContext: ModelContext

  // Persisted
  var hideAlways: Bool = false
  private(set) var blockedUsers: [BlockedUser] = []

  /// 1 = minimal, 9 = banned word list, 10 = hide all. Controls how aggressively AI flags comments.
  var sensitivityLevel: Int = 5

  // Session-only
  var hideOnce: Bool = false
  var unhideOnce: Bool = false
  var flaggedCommentIds: Set<Int> = []
  var manuallyUnhiddenCommentIds: Set<Int> = []

  var isModerationActive: Bool {
    if unhideOnce { return false }
    return hideAlways || hideOnce
  }

  init(modelContext: ModelContext) {
    self.modelContext = modelContext
    loadFromStore()
    observeRemoteChanges()
  }

  private func observeRemoteChanges() {
    NotificationCenter.default.addObserver(
      forName: NSNotification.Name.NSPersistentStoreRemoteChange,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor in
        self?.loadFromStore()
      }
    }
  }

  // MARK: - Visibility Logic

  /// Whether the comment should be completely removed from the list (not even [Hidden] shown).
  func shouldRemoveComment(_ comment: Comment) -> Bool {
    blockLevel(for: comment.by) == "remove"
  }

  func shouldHideComment(_ comment: Comment) -> Bool {
    // 1. "remove"-level blocked user — completely removed (handled by shouldRemoveComment)
    if blockLevel(for: comment.by) == "remove" {
      return false
    }
    // 2. "hide"-level blocked user — hidden unless manually unhidden
    if blockLevel(for: comment.by) == "hide" {
      return !manuallyUnhiddenCommentIds.contains(comment.id)
    }
    // 3. Sensitivity 10 + moderation active — hide all (testing bypass)
    if sensitivityLevel >= 10 && isModerationActive {
      return !manuallyUnhiddenCommentIds.contains(comment.id)
    }
    // 4. AI-flagged and moderation active — hidden unless manually unhidden
    if flaggedCommentIds.contains(comment.id) && isModerationActive {
      return !manuallyUnhiddenCommentIds.contains(comment.id)
    }
    return false
  }

  func canUnhide(_ comment: Comment) -> Bool {
    blockLevel(for: comment.by) != "remove"
  }

  func unhideComment(_ commentId: Int) {
    manuallyUnhiddenCommentIds.insert(commentId)
  }

  // MARK: - Preferences

  func setHideAlways(_ value: Bool) {
    hideAlways = value
    persistPreferences()
  }

  func setSensitivityLevel(_ level: Int) {
    sensitivityLevel = max(1, min(10, level))
    persistPreferences()
  }

  private func persistPreferences() {
    let identifier = "default"
    let predicate = #Predicate<ModerationPreference> { $0.identifier == identifier }
    let descriptor = FetchDescriptor(predicate: predicate)
    if let existing = try? modelContext.fetch(descriptor).first {
      existing.hideAlways = hideAlways
      existing.sensitivityLevel = sensitivityLevel
    } else {
      let pref = ModerationPreference(hideAlways: hideAlways, sensitivityLevel: sensitivityLevel)
      modelContext.insert(pref)
    }
    try? modelContext.save()
  }

  // MARK: - Block List

  func blockUser(_ username: String, level: String) {
    // Update existing or create new
    let predicate = #Predicate<BlockedUser> { $0.username == username }
    let descriptor = FetchDescriptor(predicate: predicate)
    if let existing = try? modelContext.fetch(descriptor).first {
      existing.blockLevel = level
      existing.blockedAt = Date()
    } else {
      let blocked = BlockedUser(username: username, blockLevel: level)
      modelContext.insert(blocked)
      blockedUsers.append(blocked)
    }
    try? modelContext.save()
  }

  func isBlocked(_ username: String) -> Bool {
    blockedUsers.contains { $0.username == username }
  }

  func blockLevel(for username: String) -> String? {
    blockedUsers.first { $0.username == username }?.blockLevel
  }

  // MARK: - Session Reset

  func resetSession() {
    hideOnce = false
    unhideOnce = false
    flaggedCommentIds.removeAll()
    manuallyUnhiddenCommentIds.removeAll()
  }

  // MARK: - Store Loading

  func loadFromStore() {
    // Load preference
    let identifier = "default"
    let prefPredicate = #Predicate<ModerationPreference> { $0.identifier == identifier }
    let prefDescriptor = FetchDescriptor(predicate: prefPredicate)
    if let pref = try? modelContext.fetch(prefDescriptor).first {
      hideAlways = pref.hideAlways
      sensitivityLevel = max(1, pref.sensitivityLevel)
    }

    // Load blocked users
    let blockedDescriptor = FetchDescriptor<BlockedUser>(
      sortBy: [SortDescriptor(\.blockedAt, order: .reverse)]
    )
    if let stored = try? modelContext.fetch(blockedDescriptor) {
      blockedUsers = stored
    }
  }
}
