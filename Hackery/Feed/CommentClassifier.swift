//
//  CommentClassifier.swift
//  Hackery
//
//  Created by Tim Shim on 31/3/26.
//  Copyright © 2026 Tim Shim. All rights reserved.
//

import Foundation
import FoundationModels

@Generable
struct CommentClassification {
  @Guide(description: "Whether the comment contains offensive, toxic, or objectionable content")
  var isObjectionable: Bool
}

@MainActor
@Observable
final class CommentClassifier {
  private var session: LanguageModelSession?

  var isAvailable: Bool {
    #if targetEnvironment(simulator)
    return false
    #else
    return SystemLanguageModel.default.isAvailable
    #endif
  }
  var classifyingCommentIds: Set<Int> = []

  /// Cache: (commentId, sensitivityLevel) -> isObjectionable
  /// Prevents non-deterministic AI results when re-classifying at the same level.
  private var classificationCache: [Int: [Int: Bool]] = [:]

  init() {
    #if !targetEnvironment(simulator)
    if SystemLanguageModel.default.isAvailable {
      session = LanguageModelSession()
    }
    #endif
  }

  // MARK: - Banned Word List (Sensitivity 9)

  /// Words that trigger hiding at sensitivity 9.
  /// Case-insensitive whole-word matching.
  nonisolated static let bannedWords: Set<String> = [
    // Profanity
    "fuck", "fucking", "shit", "shitty", "ass", "asshole", "bitch", "bastard", "damn", "crap",
    "dick", "piss", "bullshit", "dumbass", "jackass", "motherfucker",
    // Slurs and hate speech
    "retard", "retarded", "idiot", "moron", "stupid", "dumb", "imbecile",
    // Hostility
    "kill", "die", "death", "threat", "hate", "loser", "pathetic", "worthless", "trash", "garbage",
    "disgusting", "awful", "terrible", "horrible", "worst",
    // Dismissiveness
    "shut up", "nobody cares", "who cares", "useless", "pointless", "waste",
    // Negative tone
    "no", "not", "never", "can't", "won't", "don't", "couldn't", "shouldn't", "wouldn't",
    "bad", "evil", "wrong", "fail", "failed", "failure", "broken", "ugly", "boring", "sucks",
    "annoying", "frustrating", "disappointed", "disappointing", "mediocre", "overrated",
    "underwhelming", "lacking", "flawed", "inferior", "poor", "weak", "lame", "meh",
    "unfortunately", "sadly", "regret", "mistake", "error", "problem", "issue", "bug",
    "slow", "laggy", "clunky", "outdated", "obsolete", "bloated", "overcomplicated",
    "confusing", "unclear", "misleading", "deceptive", "sketchy", "suspicious", "shady",
    "annoyed", "angry", "furious", "upset", "irritated", "aggravated", "outraged",
    "ridiculous", "absurd", "laughable", "joke", "scam", "fraud", "ripoff",
    "incompetent", "clueless", "ignorant", "arrogant", "pretentious", "obnoxious",
    "toxic", "hostile", "aggressive", "nasty", "vile", "gross", "creepy",
    "impossible", "hopeless", "doomed", "ruined", "destroyed", "wrecked",
    "overpriced", "expensive", "cheap", "stingy", "greedy",
    "tired", "exhausting", "tedious", "repetitive", "dull", "stale", "bland",
    "reject", "rejected", "deny", "denied", "refuse", "refused", "abandon", "abandoned",
    "complain", "complaint", "rant", "whine", "nag",
    "worse", "inferior", "subpar", "unacceptable", "intolerable", "unbearable",
  ]

  /// Checks if text contains any banned word (case-insensitive, word boundary matching).
  nonisolated static func containsBannedWord(_ text: String) -> Bool {
    let lowered = text.lowercased()
    for word in bannedWords {
      if word.contains(" ") {
        // Multi-word phrases: simple contains check
        if lowered.contains(word) { return true }
      } else {
        // Single words: check word boundaries to avoid partial matches
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
        if lowered.range(of: pattern, options: .regularExpression) != nil {
          return true
        }
      }
    }
    return false
  }

  // MARK: - AI Classification Prompt (Sensitivity 1-8)

  /// Builds the classification prompt based on sensitivity level (1-8).
  /// 0 = off (returns nil)
  /// 1-2 = lenient (only flag extremely offensive content)
  /// 3-4 = moderate-low (flag clearly offensive and hateful content)
  /// 5-6 = moderate (flag insults, toxicity, and harassment)
  /// 7-8 = strict (flag mildly rude, dismissive, or passive-aggressive content)
  /// 9 = banned word list (no AI, uses containsBannedWord instead)
  /// 10 = testing bypass (hides all comments without calling the classifier)
  nonisolated static func buildPrompt(for commentText: String, sensitivityLevel: Int) -> String? {
    guard sensitivityLevel > 0, sensitivityLevel <= 8 else { return nil }

    let criteria: String
    switch sensitivityLevel {
    case 1...2:
      criteria = "Only flag comments that contain extremely offensive content such as slurs, explicit hate speech, direct threats of violence, or severe harassment. Mildly rude or sarcastic comments should NOT be flagged."
    case 3...4:
      criteria = "Flag comments that contain clearly offensive or hateful content. This includes slurs, hate speech, threats, severe harassment, and dehumanizing language. Do not flag comments that are merely blunt, sarcastic, or express strong disagreement."
    case 5...6:
      criteria = "Flag comments that contain offensive, toxic, hateful, or objectionable content. This includes insults, name-calling, bigotry, harassment, and dehumanizing language. Do not flag comments that are merely blunt, sarcastic, or express disagreement."
    case 7...8:
      criteria = "Flag comments that are rude, dismissive, passive-aggressive, condescending, or mildly hostile in addition to clearly offensive content. Comments that attack ideas respectfully should not be flagged, but personal attacks of any severity should be."
    default:
      criteria = "Flag comments that contain offensive, toxic, hateful, or objectionable content."
    }

    return "Classify whether the following user comment is objectionable based on these criteria: \(criteria)\n\nComment: \(commentText)"
  }

  // MARK: - Classification

  /// Classifies a single text string. Returns true if objectionable.
  func classifyText(_ text: String, sensitivityLevel: Int) async -> Bool {
    guard sensitivityLevel > 0 else { return false }

    // Sensitivity 9: banned word list
    if sensitivityLevel >= 9 {
      return Self.containsBannedWord(text)
    }

    // Sensitivity 1-8: AI classification
    guard let session,
          let prompt = Self.buildPrompt(for: text, sensitivityLevel: sensitivityLevel) else {
      return false
    }
    do {
      let response = try await session.respond(to: prompt, generating: CommentClassification.self)
      return response.content.isObjectionable
    } catch {
      return false
    }
  }

  func classify(_ comments: [Comment], sensitivityLevel: Int) async -> Set<Int> {
    guard sensitivityLevel > 0 else { return [] }

    // Sensitivity 9: banned word list (no AI needed, runs off main thread)
    if sensitivityLevel >= 9 {
      let commentPairs = comments.map { ($0.id, $0.text) }
      let flagged: Set<Int> = await Task.detached {
        var result = Set<Int>()
        for (id, text) in commentPairs {
          if CommentClassifier.containsBannedWord(text) {
            result.insert(id)
          }
        }
        return result
      }.value
      return flagged
    }

    // Sensitivity 1-8: AI classification
    guard let session else { return [] }

    classifyingCommentIds.formUnion(comments.map(\.id))

    var flagged = Set<Int>()
    for comment in comments {
      // Check cache first
      if let cached = classificationCache[comment.id]?[sensitivityLevel] {
        if cached { flagged.insert(comment.id) }
        classifyingCommentIds.remove(comment.id)
        continue
      }
      do {
        guard let prompt = Self.buildPrompt(for: comment.text, sensitivityLevel: sensitivityLevel) else {
          classifyingCommentIds.remove(comment.id)
          continue
        }
        let response = try await session.respond(to: prompt, generating: CommentClassification.self)
        let isObjectionable = response.content.isObjectionable
        // Cache the result
        classificationCache[comment.id, default: [:]][sensitivityLevel] = isObjectionable
        if isObjectionable {
          flagged.insert(comment.id)
        }
      } catch {
        // Default to not flagged on error
      }
      classifyingCommentIds.remove(comment.id)
    }
    return flagged
  }
}
