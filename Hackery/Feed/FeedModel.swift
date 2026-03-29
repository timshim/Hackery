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

struct Story: Identifiable, Hashable, Codable {
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

  init(storyId: Int, by: String, descendants: Int, kids: [Int], score: Int, time: Int, title: String, type: String, url: String, text: String?) {
    self.id = storyId
    self.by = by
    self.descendants = descendants
    self.kids = kids
    self.score = score
    self.time = time
    self.title = title
    self.type = type
    self.url = url
    self.text = text
  }

  init(from item: HNItem) {
    self.init(
      storyId: item.id,
      by: item.by ?? "[deleted]",
      descendants: item.descendants ?? 0,
      kids: item.kids ?? [],
      score: item.score ?? 0,
      time: item.time ?? 0,
      title: (item.title ?? "").decodingHTMLEntities,
      type: item.type ?? "story",
      url: item.url ?? "",
      text: item.text
    )
  }

  private enum CodingKeys: String, CodingKey {
    case id, by, descendants, kids, score, time, title, type, url, text
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
  let depth: Int

  var timeAgo: String {
    Date(timeIntervalSince1970: TimeInterval(time)).relativeTime
  }

  init(from item: HNItem, parsedText: String? = nil, depth: Int = 0) {
    self.id = item.id
    self.by = item.by ?? "[deleted]"
    self.kids = item.kids ?? []
    self.parent = item.parent ?? 0
    self.text = parsedText ?? item.text ?? "[removed]"
    self.time = item.time ?? 0
    self.type = item.type ?? "comment"
    self.deleted = item.deleted ?? false
    self.dead = item.dead ?? false
    self.depth = depth
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
