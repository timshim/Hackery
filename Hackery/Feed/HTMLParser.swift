//
//  HTMLParser.swift
//  Hackery
//
//  Created by Tim Shim on 30/3/26.
//  Copyright © 2026 Tim Shim. All rights reserved.
//

import Foundation

enum HTMLParser {

  static func parse(_ html: String) -> String {
    var result = html

    // Convert <a href="url">text</a> to markdown [text](url)
    if let linkRegex = try? NSRegularExpression(pattern: "<a\\s[^>]*href\\s*=\\s*\"([^\"]*)\"[^>]*>(.*?)</a>", options: .caseInsensitive) {
      let range = NSRange(result.startIndex..., in: result)
      let mutable = NSMutableString(string: result)
      let matches = linkRegex.matches(in: result, range: range).reversed()
      for match in matches {
        guard let hrefRange = Range(match.range(at: 1), in: result),
              let textRange = Range(match.range(at: 2), in: result),
              let _ = Range(match.range, in: result) else { continue }
        let href = String(result[hrefRange])
        let text = String(result[textRange])
          .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        let escaped = text
          .replacingOccurrences(of: "[", with: "\\[")
          .replacingOccurrences(of: "]", with: "\\]")
        let markdown = "[\(escaped)](\(href))"
        mutable.replaceCharacters(in: match.range, with: markdown)
      }
      result = mutable as String
    }

    // Convert block elements to newlines
    result = result.replacingOccurrences(of: "<p[^>]*>", with: "\n\n", options: .regularExpression)
    result = result.replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: .regularExpression)

    // Strip remaining HTML tags
    result = result.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

    // Decode HTML entities
    result = result.decodingHTMLEntities

    // Decode numeric HTML entities (&#123; and &#x1F;)
    if let hexRegex = try? NSRegularExpression(pattern: "&#x([0-9a-fA-F]+);") {
      let range = NSRange(result.startIndex..., in: result)
      let mutable = NSMutableString(string: result)
      for match in hexRegex.matches(in: result, range: range).reversed() {
        guard let codeRange = Range(match.range(at: 1), in: result) else { continue }
        if let code = UInt32(result[codeRange], radix: 16), let scalar = Unicode.Scalar(code) {
          mutable.replaceCharacters(in: match.range, with: String(Character(scalar)))
        }
      }
      result = mutable as String
    }
    if let decRegex = try? NSRegularExpression(pattern: "&#(\\d+);") {
      let range = NSRange(result.startIndex..., in: result)
      let mutable = NSMutableString(string: result)
      for match in decRegex.matches(in: result, range: range).reversed() {
        guard let codeRange = Range(match.range(at: 1), in: result) else { continue }
        if let code = UInt32(result[codeRange]), let scalar = Unicode.Scalar(code) {
          mutable.replaceCharacters(in: match.range, with: String(Character(scalar)))
        }
      }
      result = mutable as String
    }

    return result.trimmingCharacters(in: .whitespacesAndNewlines)
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
