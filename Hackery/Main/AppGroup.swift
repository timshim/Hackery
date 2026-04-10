//
//  AppGroup.swift
//  Hackery
//
//  Shared App Group identifiers and container paths used by the main app,
//  widget extension, and share extension.
//

import Foundation

enum AppGroup {
  static let identifier = "group.com.timshim.Hackery"

  static var containerURL: URL? {
    FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
  }

  static var bookmarksSnapshotURL: URL? {
    containerURL?.appendingPathComponent("bookmarks.json")
  }

  static var topStoriesSnapshotURL: URL? {
    containerURL?.appendingPathComponent("topstories.json")
  }
}
