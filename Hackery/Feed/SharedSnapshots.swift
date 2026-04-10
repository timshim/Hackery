//
//  SharedSnapshots.swift
//  Hackery
//
//  JSON snapshots of bookmarks and top stories written to the App Group
//  container so the widget extension can read them without any dependency
//  on SwiftData or the HN API.
//

import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

enum SharedSnapshots {

  static func writeBookmarks(_ stories: [Story]) {
    guard let url = AppGroup.bookmarksSnapshotURL else { return }
    write(stories, to: url)
    reloadWidgets(kinds: ["Bookmarks"])
  }

  static func writeTopStories(_ stories: [Story]) {
    guard let url = AppGroup.topStoriesSnapshotURL else { return }
    // Cap to what widgets actually need — large sizes show at most ~6.
    let trimmed = Array(stories.prefix(10))
    write(trimmed, to: url)
    reloadWidgets(kinds: ["TopStory", "TopStories"])
  }

  static func readBookmarks() -> [Story] {
    guard let url = AppGroup.bookmarksSnapshotURL else { return [] }
    return read(from: url)
  }

  static func readTopStories() -> [Story] {
    guard let url = AppGroup.topStoriesSnapshotURL else { return [] }
    return read(from: url)
  }

  // MARK: - Private

  private static func write(_ stories: [Story], to url: URL) {
    do {
      let data = try JSONEncoder().encode(stories)
      try data.write(to: url, options: .atomic)
    } catch {
      // Non-fatal: snapshot is a best-effort mirror.
    }
  }

  private static func read(from url: URL) -> [Story] {
    guard let data = try? Data(contentsOf: url) else { return [] }
    return (try? JSONDecoder().decode([Story].self, from: data)) ?? []
  }

  private static func reloadWidgets(kinds: [String]) {
    #if canImport(WidgetKit) && !os(visionOS)
    for kind in kinds {
      WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }
    #endif
  }
}
