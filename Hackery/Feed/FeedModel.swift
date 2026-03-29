//
//  FeedModel.swift
//  Hackery
//
//  Created by Tim Shim on 6/17/19.
//  Copyright © 2019 Tim Shim. All rights reserved.
//

import Foundation

// Matches the HN API schema exactly — all fields optional except id
struct HNItem: Codable {
  let id: Int
  let type: String?
  let by: String?
  let time: Int?
  let text: String?
  let url: String?
  let title: String?
  let score: Int?
  let descendants: Int?
  let kids: [Int]?
  let parent: Int?
  let deleted: Bool?
  let dead: Bool?
  let poll: Int?
  let parts: [Int]?
}

struct Story: Identifiable, Hashable {
  let id: Int
  let by: String
  let descendants: Int
  let kids: [Int]
  let score: Int
  let time: Int
  let title: String
  let type: String
  let url: String
  let text: String?

  var timeAgo: String {
    Date(timeIntervalSince1970: TimeInterval(time)).relativeTime
  }

  init(from item: HNItem) {
    self.id = item.id
    self.by = item.by ?? "[deleted]"
    self.descendants = item.descendants ?? 0
    self.kids = item.kids ?? []
    self.score = item.score ?? 0
    self.time = item.time ?? 0
    self.title = (item.title ?? "").decodingHTMLEntities
    self.type = item.type ?? "story"
    self.url = item.url ?? ""
    self.text = item.text
  }
}

struct Comment: Identifiable, Hashable {
  let id: Int
  let by: String
  let kids: [Int]
  let parent: Int
  let text: String
  let time: Int
  let type: String
  let deleted: Bool
  let dead: Bool

  var timeAgo: String {
    Date(timeIntervalSince1970: TimeInterval(time)).relativeTime
  }

  init(from item: HNItem, parsedText: String? = nil) {
    self.id = item.id
    self.by = item.by ?? "[deleted]"
    self.kids = item.kids ?? []
    self.parent = item.parent ?? 0
    self.text = parsedText ?? item.text ?? "[removed]"
    self.time = item.time ?? 0
    self.type = item.type ?? "comment"
    self.deleted = item.deleted ?? false
    self.dead = item.dead ?? false
  }
}

private extension String {
  var decodingHTMLEntities: String {
    var result = self
    let entities = [
      "&amp;": "&", "&lt;": "<", "&gt;": ">",
      "&quot;": "\"", "&#39;": "'", "&apos;": "'",
      "&#x27;": "'", "&#x2F;": "/", "&#38;": "&",
    ]
    for (entity, char) in entities {
      result = result.replacingOccurrences(of: entity, with: char)
    }
    return result
  }
}
