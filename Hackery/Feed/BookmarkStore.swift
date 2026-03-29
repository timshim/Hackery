//
//  BookmarkStore.swift
//  Hackery
//
//  Created by Tim Shim on 29/3/26.
//  Copyright © 2026 Tim Shim. All rights reserved.
//

import SwiftUI

@MainActor
@Observable
final class BookmarkStore {
  private static let storageKey = "bookmarkedStories"

  var bookmarks: [Story] = []

  init() {
    loadFromDisk()
  }

  var bookmarkedIds: Set<Int> {
    Set(bookmarks.map(\.id))
  }

  func isBookmarked(_ story: Story) -> Bool {
    bookmarkedIds.contains(story.id)
  }

  func toggle(_ story: Story) {
    if isBookmarked(story) {
      bookmarks.removeAll { $0.id == story.id }
    } else {
      bookmarks.insert(story, at: 0)
    }
    saveToDisk()
  }

  private func saveToDisk() {
    guard let data = try? JSONEncoder().encode(bookmarks) else { return }
    UserDefaults.standard.set(data, forKey: Self.storageKey)
  }

  private func loadFromDisk() {
    guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
          let stored = try? JSONDecoder().decode([Story].self, from: data) else {
      return
    }
    bookmarks = stored
  }
}
