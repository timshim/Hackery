//
//  Shared.swift
//  HackeryShare
//
//  Share-extension-specific types. The shared types (AppGroup,
//  FeedModel) come from the main app via target membership.
//

import Foundation

// Extensions that FeedModel.swift depends on (Extensions.swift / HTMLParser.swift
// are not included in this target).

extension Date {
  var relativeTime: String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    return formatter.localizedString(for: self, relativeTo: Date())
  }
}

extension String {
  var decodingHTMLEntities: String {
    var result = self
    let entities = [
      "&amp;": "&", "&lt;": "<", "&gt;": ">",
      "&quot;": "\"", "&#39;": "'", "&apos;": "'",
      "&#x27;": "'", "&#x2F;": "/", "&#38;": "&",
      "&nbsp;": " ",
    ]
    for (entity, char) in entities {
      result = result.replacingOccurrences(of: entity, with: char)
    }
    return result
  }
}

// MARK: - Algolia Search Result

struct AlgoliaResponse: Codable {
  let hits: [AlgoliaHit]
}

struct AlgoliaHit: Codable {
  let objectID: String
  let title: String?
  let points: Int?
  let num_comments: Int?
}
