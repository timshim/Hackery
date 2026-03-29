//
//  HTMLParserTests.swift
//  HackeryTests
//
//  Created by Tim Shim on 30/3/26.
//  Copyright © 2026 Tim Shim. All rights reserved.
//

import Testing
@testable import Hackery

struct HTMLParserTests {

  // MARK: - Link conversion

  @Test func convertsSimpleLink() {
    let html = #"<a href="https://example.com">Example</a>"#
    let result = HTMLParser.parse(html)
    #expect(result == "[Example](https://example.com)")
  }

  @Test func convertsLinkWithAttributes() {
    let html = #"<a href="https://example.com" rel="nofollow">Example</a>"#
    let result = HTMLParser.parse(html)
    #expect(result == "[Example](https://example.com)")
  }

  @Test func convertsMultipleLinks() {
    let html = #"<a href="https://a.com">A</a> and <a href="https://b.com">B</a>"#
    let result = HTMLParser.parse(html)
    #expect(result == "[A](https://a.com) and [B](https://b.com)")
  }

  @Test func escapesMarkdownBracketsInLinkText() {
    let html = #"<a href="https://example.com">[test]</a>"#
    let result = HTMLParser.parse(html)
    #expect(result == "[\\[test\\]](https://example.com)")
  }

  @Test func stripsNestedTagsInsideLink() {
    let html = #"<a href="https://example.com"><i>italic</i> text</a>"#
    let result = HTMLParser.parse(html)
    #expect(result == "[italic text](https://example.com)")
  }

  // MARK: - Block elements

  @Test func convertsParagraphsToNewlines() {
    let html = "<p>First paragraph</p><p>Second paragraph</p>"
    let result = HTMLParser.parse(html)
    #expect(result == "First paragraph\n\nSecond paragraph")
  }

  @Test func convertsBreaksToNewlines() {
    let html = "Line one<br>Line two<br/>Line three"
    let result = HTMLParser.parse(html)
    #expect(result == "Line one\nLine two\nLine three")
  }

  @Test func convertsSelfClosingBreak() {
    let html = "Hello<br />World"
    let result = HTMLParser.parse(html)
    #expect(result == "Hello\nWorld")
  }

  // MARK: - Tag stripping

  @Test func stripsRemainingHTMLTags() {
    let html = "<strong>Bold</strong> and <em>italic</em>"
    let result = HTMLParser.parse(html)
    #expect(result == "Bold and italic")
  }

  @Test func handlesPlainText() {
    let result = HTMLParser.parse("No HTML here")
    #expect(result == "No HTML here")
  }

  // MARK: - Named entity decoding

  @Test func decodesCommonNamedEntities() {
    let html = "&amp; &lt; &gt; &quot;"
    let result = HTMLParser.parse(html)
    #expect(result == #"& < > ""#)
  }

  @Test func decodesApostropheVariants() {
    let html = "&#39; &apos; &#x27;"
    let result = HTMLParser.parse(html)
    #expect(result == "' ' '")
  }

  @Test func decodesNbsp() {
    let html = "hello&nbsp;world"
    let result = HTMLParser.parse(html)
    #expect(result == "hello world")
  }

  // MARK: - Numeric entity decoding

  @Test func decodesDecimalEntities() {
    let html = "&#65;&#66;&#67;"  // ABC
    let result = HTMLParser.parse(html)
    #expect(result == "ABC")
  }

  @Test func decodesHexEntities() {
    let html = "&#x41;&#x42;&#x43;"  // ABC
    let result = HTMLParser.parse(html)
    #expect(result == "ABC")
  }

  @Test func decodesEmojiHexEntity() {
    let html = "&#x1F600;"  // 😀
    let result = HTMLParser.parse(html)
    #expect(result == "😀")
  }

  // MARK: - Combined / real-world

  @Test func handlesTypicalHNComment() {
    let html = """
    <p>This is a comment with a <a href="https://example.com" rel="nofollow">link</a>.</p>\
    <p>Second paragraph with &amp; entities.</p>
    """
    let result = HTMLParser.parse(html)
    #expect(result.contains("[link](https://example.com)"))
    #expect(result.contains("& entities"))
    #expect(!result.contains("<"))
  }

  @Test func handlesEmptyString() {
    let result = HTMLParser.parse("")
    #expect(result == "")
  }

  @Test func trimsWhitespace() {
    let html = "  <p>  text  </p>  "
    let result = HTMLParser.parse(html)
    #expect(result == "text")
  }

  // MARK: - String.decodingHTMLEntities

  @Test func stringExtensionDecodesEntities() {
    let input = "Tom &amp; Jerry &lt;3"
    #expect(input.decodingHTMLEntities == "Tom & Jerry <3")
  }

  @Test func stringExtensionPassesThroughCleanText() {
    let input = "No entities here"
    #expect(input.decodingHTMLEntities == "No entities here")
  }
}
