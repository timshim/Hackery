//
//  StoryCache.swift
//  Hackery
//
//  Created by Tim Shim on 29/3/26.
//  Copyright © 2026 Tim Shim. All rights reserved.
//

import Foundation

struct StoryCache: Sendable {
  private static let cacheKey = "cachedStories"
  private static let cacheTimestampKey = "cachedStoriesTimestamp"
  private static let maxAge: TimeInterval = 60 * 30 // 30 minutes

  static func save(_ stories: [Story]) {
    guard let data = try? JSONEncoder().encode(stories) else { return }
    UserDefaults.standard.set(data, forKey: cacheKey)
    UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: cacheTimestampKey)
  }

  static func load() -> [Story]? {
    let timestamp = UserDefaults.standard.double(forKey: cacheTimestampKey)
    guard timestamp > 0 else { return nil }

    let age = Date().timeIntervalSince1970 - timestamp
    guard age < maxAge else { return nil }

    guard let data = UserDefaults.standard.data(forKey: cacheKey),
          let stories = try? JSONDecoder().decode([Story].self, from: data) else {
      return nil
    }
    return stories
  }

  static func clear() {
    UserDefaults.standard.removeObject(forKey: cacheKey)
    UserDefaults.standard.removeObject(forKey: cacheTimestampKey)
  }
}
