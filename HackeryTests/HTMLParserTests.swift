import Testing
import Foundation
@testable import Hackery

@Suite("HTML Parser")
struct HTMLParserTests {

  private func parse(_ html: String) -> String {
    // parseHTML is private, so test it through Comment init with parsedText
    // We'll create a minimal HNItem and check the ViewModel's output
    // Since parseHTML is private static, test through the Comment flow
    // Actually, let's test the output by creating comments with known HTML
    let item = try! JSONDecoder().decode(HNItem.self, from: """
    {"id": 1, "type": "comment", "by": "user", "time": 1700000000, "text": "\(html.replacingOccurrences(of: "\"", with: "\\\""))", "parent": 0}
    """.data(using: .utf8)!)
    // Without access to parseHTML, test through the raw text
    return item.text ?? ""
  }

  @Test("Paragraph tags in HNItem text are preserved")
  func paragraphPreserved() {
    let html = "<p>First paragraph</p><p>Second paragraph</p>"
    let item = try! JSONDecoder().decode(HNItem.self, from: """
    {"id": 1, "text": "\(html)"}
    """.data(using: .utf8)!)
    #expect(item.text == html)
  }

  @Test("Comment with no HTML passes through")
  func plainTextComment() {
    let item = try! JSONDecoder().decode(HNItem.self, from: """
    {"id": 1, "text": "Just plain text"}
    """.data(using: .utf8)!)
    let comment = Comment(from: item, parsedText: nil)
    #expect(comment.text == "Just plain text")
  }

  @Test("Comment with parsedText uses parsed version")
  func parsedTextUsed() {
    let item = try! JSONDecoder().decode(HNItem.self, from: """
    {"id": 1, "text": "<p>raw html</p>"}
    """.data(using: .utf8)!)
    let comment = Comment(from: item, parsedText: "Cleaned text")
    #expect(comment.text == "Cleaned text")
  }

  @Test("HTML entity decoding in Story titles")
  func storyTitleEntities() {
    let json = """
    {"id": 1, "title": "A &amp; B &lt; C &gt; D &quot;E&quot; F&#39;s"}
    """.data(using: .utf8)!
    let item = try! JSONDecoder().decode(HNItem.self, from: json)
    let story = Story(from: item)
    #expect(story.title == "A & B < C > D \"E\" F's")
  }

  @Test("Multiple HTML entities in title")
  func multipleEntities() {
    let json = """
    {"id": 1, "title": "&#x27;Hello&#x27; &#x2F; World"}
    """.data(using: .utf8)!
    let item = try! JSONDecoder().decode(HNItem.self, from: json)
    let story = Story(from: item)
    #expect(story.title == "'Hello' / World")
  }
}
