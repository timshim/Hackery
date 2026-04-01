//
//  BookmarkStore.swift
//  Hackery
//
//  Created by Tim Shim on 29/3/26.
//  Copyright © 2026 Tim Shim. All rights reserved.
//

import SwiftUI
import SwiftData
import CoreData

@Model
final class BookmarkedStory {
  var storyId: Int = 0
  var by: String = ""
  var descendants: Int = 0
  var kids: [Int] = []
  var score: Int = 0
  var time: Int = 0
  var title: String = ""
  var type: String = "story"
  var url: String = ""
  var text: String?
  var bookmarkedAt: Date = Date.distantPast

  init(from story: Story) {
    self.storyId = story.id
    self.by = story.by
    self.descendants = story.descendants
    self.kids = story.kids
    self.score = story.score
    self.time = story.time
    self.title = story.title
    self.type = story.type
    self.url = story.url
    self.text = story.text
    self.bookmarkedAt = Date()
  }

  func toStory() -> Story {
    Story(
      storyId: storyId,
      by: by,
      descendants: descendants,
      kids: kids,
      score: score,
      time: time,
      title: title,
      type: type,
      url: url,
      text: text
    )
  }
}

@MainActor
@Observable
final class BookmarkStore {
  private var modelContext: ModelContext

  var bookmarks: [Story] = []

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

  var bookmarkedIds: Set<Int> {
    Set(bookmarks.map(\.id))
  }

  func isBookmarked(_ story: Story) -> Bool {
    bookmarkedIds.contains(story.id)
  }

  func toggle(_ story: Story) {
    if isBookmarked(story) {
      let storyId = story.id
      let predicate = #Predicate<BookmarkedStory> { $0.storyId == storyId }
      let descriptor = FetchDescriptor(predicate: predicate)
      if let existing = try? modelContext.fetch(descriptor).first {
        modelContext.delete(existing)
      }
      bookmarks.removeAll { $0.id == story.id }
    } else {
      let bookmarked = BookmarkedStory(from: story)
      modelContext.insert(bookmarked)
      bookmarks.insert(story, at: 0)
    }
    try? modelContext.save()
  }

  private func loadFromStore() {
    let descriptor = FetchDescriptor<BookmarkedStory>(
      sortBy: [SortDescriptor(\.bookmarkedAt, order: .reverse)]
    )
    guard let stored = try? modelContext.fetch(descriptor) else { return }
    bookmarks = stored.map { $0.toStory() }
  }
}
