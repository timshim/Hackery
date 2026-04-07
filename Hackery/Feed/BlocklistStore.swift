//
//  BlocklistStore.swift
//  Hackery
//
//  Created by Tim Shim on 7/4/26.
//  Copyright © 2026 Tim Shim. All rights reserved.
//

import SwiftUI
import SwiftData
import CoreData

@Model
final class BlockedStory {
  var storyId: Int = 0
  var title: String = ""
  var by: String = ""
  var blockedAt: Date = Date.distantPast

  init(from story: Story) {
    self.storyId = story.id
    self.title = story.title
    self.by = story.by
    self.blockedAt = Date()
  }
}

@MainActor
@Observable
final class BlocklistStore {
  private var modelContext: ModelContext

  var blockedStoryIds: Set<Int> = []

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

  func isBlocked(_ story: Story) -> Bool {
    blockedStoryIds.contains(story.id)
  }

  func block(_ story: Story) {
    guard !isBlocked(story) else { return }
    let blocked = BlockedStory(from: story)
    modelContext.insert(blocked)
    blockedStoryIds.insert(story.id)
    try? modelContext.save()
  }

  func unblock(_ storyId: Int) {
    let predicate = #Predicate<BlockedStory> { $0.storyId == storyId }
    let descriptor = FetchDescriptor(predicate: predicate)
    if let existing = try? modelContext.fetch(descriptor).first {
      modelContext.delete(existing)
    }
    blockedStoryIds.remove(storyId)
    try? modelContext.save()
  }

  private func loadFromStore() {
    let descriptor = FetchDescriptor<BlockedStory>(
      sortBy: [SortDescriptor(\.blockedAt, order: .reverse)]
    )
    guard let stored = try? modelContext.fetch(descriptor) else { return }
    blockedStoryIds = Set(stored.map { $0.storyId })
  }
}
