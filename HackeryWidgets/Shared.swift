//
//  Shared.swift
//  HackeryWidgets
//
//  Widget-specific helpers. The shared types (Story, AppGroup,
//  SharedSnapshots) come from the main app via target membership.
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

extension Story {
  var domain: String {
    URL(string: url)?.host?.replacingOccurrences(of: "www.", with: "") ?? ""
  }

  init(
    id: Int, by: String, descendants: Int, kids: [Int], score: Int,
    time: Int, title: String, type: String, url: String, text: String?
  ) {
    self.init(
      storyId: id, by: by, descendants: descendants, kids: kids,
      score: score, time: time, title: title, type: type, url: url, text: text
    )
  }
}
