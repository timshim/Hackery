//
//  EngagementTracker.swift
//  Hackery
//
//  Created by Tim Shim on 4/5/26.
//  Copyright © 2026 Tim Shim. All rights reserved.
//

import SwiftUI
import StoreKit

@MainActor
@Observable
final class EngagementTracker {

  // MARK: - Prompt types

  enum Prompt: Equatable {
    case review
    case tipJar
  }

  // MARK: - State

  private(set) var pendingPrompt: Prompt?

  // MARK: - UserDefaults keys

  private enum Key {
    static let interactionCount = "engagementInteractionCount"
    static let interactionsSinceLastPrompt = "engagementSinceLastPrompt"
    static let hasShownReview = "engagementHasShownReview"
    static let tipCount = "engagementTipCount"
    static let currentInterval = "engagementCurrentInterval"
    static let phase = "engagementPhase"
  }

  // MARK: - Schedule constants

  private static let reviewThreshold = 15
  private static let tipSchedule = [30, 50]
  private static let recurringInterval = 50
  private static let postTipBaseInterval = 300

  // MARK: - Phases
  // 0 = pre-review, 1 = post-review/pre-tip-schedule, 2 = tip schedule index 0,
  // 3 = tip schedule index 1, 4 = recurring every 50, 5 = post-tip (300+)

  // MARK: - Track interaction

  func recordInteraction() {
    let total = UserDefaults.standard.integer(forKey: Key.interactionCount) + 1
    let sinceLast = UserDefaults.standard.integer(forKey: Key.interactionsSinceLastPrompt) + 1
    UserDefaults.standard.set(total, forKey: Key.interactionCount)
    UserDefaults.standard.set(sinceLast, forKey: Key.interactionsSinceLastPrompt)
  }

  func checkForPrompt() {
    let sinceLast = UserDefaults.standard.integer(forKey: Key.interactionsSinceLastPrompt)
    pendingPrompt = evaluatePrompt(sinceLastPrompt: sinceLast)
  }

  // MARK: - Evaluation

  private func evaluatePrompt(sinceLastPrompt: Int) -> Prompt? {
    let hasShownReview = UserDefaults.standard.bool(forKey: Key.hasShownReview)
    let tipCount = UserDefaults.standard.integer(forKey: Key.tipCount)

    // Post-tip phase: recurring at 300 * 2^(tipCount-1)
    if tipCount > 0 {
      let interval = Self.postTipBaseInterval * (1 << (tipCount - 1))
      if sinceLastPrompt >= interval {
        return .tipJar
      }
      return nil
    }

    // Pre-review phase
    if !hasShownReview {
      if sinceLastPrompt >= Self.reviewThreshold {
        return .review
      }
      return nil
    }

    // Post-review, escalating tip schedule
    let phase = UserDefaults.standard.integer(forKey: Key.phase)

    if phase < Self.tipSchedule.count {
      let threshold = Self.tipSchedule[phase]
      if sinceLastPrompt >= threshold {
        return .tipJar
      }
      return nil
    }

    // Recurring every 50
    if sinceLastPrompt >= Self.recurringInterval {
      return .tipJar
    }

    return nil
  }

  // MARK: - Prompt acknowledged

  func promptShown() {
    guard let prompt = pendingPrompt else { return }

    UserDefaults.standard.set(0, forKey: Key.interactionsSinceLastPrompt)

    switch prompt {
    case .review:
      UserDefaults.standard.set(true, forKey: Key.hasShownReview)
    case .tipJar:
      let tipCount = UserDefaults.standard.integer(forKey: Key.tipCount)
      if tipCount == 0 {
        let phase = UserDefaults.standard.integer(forKey: Key.phase)
        UserDefaults.standard.set(phase + 1, forKey: Key.phase)
      }
    }

    pendingPrompt = nil
  }

  // MARK: - Tip completed

  func recordTip() {
    let tipCount = UserDefaults.standard.integer(forKey: Key.tipCount) + 1
    UserDefaults.standard.set(tipCount, forKey: Key.tipCount)
    UserDefaults.standard.set(0, forKey: Key.interactionsSinceLastPrompt)
  }

  // MARK: - Request App Store review

  func requestReview() {
    if let windowScene = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .first {
      AppStore.requestReview(in: windowScene)
    }
  }
}
