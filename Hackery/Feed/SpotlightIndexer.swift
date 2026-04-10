//
//  SpotlightIndexer.swift
//  Hackery
//
//  Indexes stories into Core Spotlight so they are searchable from the
//  iOS home screen. Uses separate domains for bookmarks and feed stories
//  so they can be reindexed independently. Identifiers are hackery://
//  deep-link URLs so the activity handler routes them uniformly.
//

import Foundation
@preconcurrency import CoreSpotlight
import UniformTypeIdentifiers

enum SpotlightIndexer {
  private static let bookmarksDomain = "com.timshim.Hackery.bookmarks"
  private static let feedDomain = "com.timshim.Hackery.feed"

  // MARK: - Bookmarks

  static func reindexBookmarks(_ stories: [Story]) {
    reindex(stories, domain: bookmarksDomain)
  }

  // MARK: - Feed stories

  static func indexFeedStories(_ stories: [Story]) {
    reindex(stories, domain: feedDomain)
  }

  // MARK: - Removal

  static func remove(storyId: Int) {
    CSSearchableIndex.default()
      .deleteSearchableItems(withIdentifiers: [identifier(for: storyId)]) { _ in }
  }

  static func identifier(for storyId: Int) -> String {
    "hackery://story/\(storyId)"
  }

  // MARK: - Private

  private static func reindex(_ stories: [Story], domain: String) {
    let index = CSSearchableIndex.default()
    index.deleteSearchableItems(withDomainIdentifiers: [domain]) { _ in
      let items = stories.map { makeItem(from: $0, domain: domain) }
      guard !items.isEmpty else { return }
      index.indexSearchableItems(items) { _ in }
    }
  }

  private static func makeItem(from story: Story, domain: String) -> CSSearchableItem {
    let attrs = CSSearchableItemAttributeSet(contentType: UTType.content)
    attrs.title = story.title
    attrs.contentDescription = descriptionLine(for: story)
    attrs.keywords = keywords(for: story)
    if let url = URL(string: story.url), !story.url.isEmpty {
      attrs.contentURL = url
    }
    return CSSearchableItem(
      uniqueIdentifier: identifier(for: story.id),
      domainIdentifier: domain,
      attributeSet: attrs
    )
  }

  private static func descriptionLine(for story: Story) -> String {
    let host = URL(string: story.url)?.host ?? ""
    return "\(story.score) points by \(story.by) • \(host)"
  }

  private static func keywords(for story: Story) -> [String] {
    var kw = ["Hacker News", "Hackery", story.by]
    if let host = URL(string: story.url)?.host { kw.append(host) }
    return kw
  }
}
