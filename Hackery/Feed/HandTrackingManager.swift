//
//  HandTrackingManager.swift
//  Hackery
//
//  Created by Claude on 4/4/26.
//  Copyright © 2026 Tim Shim. All rights reserved.
//

#if os(visionOS)
import ARKit
import SwiftUI

@Observable
final class HandTrackingManager {
  private(set) var thumbsUpDetected = false

  private let session = ARKitSession()
  private let handTracking = HandTrackingProvider()
  private var trackingTask: Task<Void, Never>?

  // Require the pose to hold for this duration to avoid false positives
  private let holdDuration: TimeInterval = 1.0
  private var thumbsUpStartTime: Date?

  var isAvailable: Bool {
    HandTrackingProvider.isSupported
  }

  func start() async {
    guard HandTrackingProvider.isSupported else { return }
    do {
      try await session.run([handTracking])
      trackingTask = Task { await processUpdates() }
    } catch {
      // Hand tracking unavailable — ornament button remains as fallback
    }
  }

  func stop() {
    trackingTask?.cancel()
    trackingTask = nil
    session.stop()
  }

  func resetDetection() {
    thumbsUpDetected = false
    thumbsUpStartTime = nil
  }

  // MARK: - Processing

  private func processUpdates() async {
    for await update in handTracking.anchorUpdates {
      guard update.event == .updated else { continue }
      let anchor = update.anchor
      guard anchor.isTracked else {
        thumbsUpStartTime = nil
        continue
      }
      let isThumbsUp = checkThumbsUp(anchor.handSkeleton)
      if isThumbsUp {
        if thumbsUpStartTime == nil {
          thumbsUpStartTime = Date()
        } else if let start = thumbsUpStartTime,
                  Date().timeIntervalSince(start) >= holdDuration,
                  !thumbsUpDetected {
          thumbsUpDetected = true
        }
      } else {
        thumbsUpStartTime = nil
      }
    }
  }

  // MARK: - Pose Detection

  /// Detects a thumbs-up pose by checking:
  /// 1. Thumb tip is above thumb intermediate joint (extended upward)
  /// 2. All other fingertips are below their respective intermediate joints (curled)
  private func checkThumbsUp(_ skeleton: HandSkeleton?) -> Bool {
    guard let skeleton else { return false }

    let thumbTip = skeleton.joint(.thumbTip)
    let thumbIntermediate = skeleton.joint(.thumbIntermediateTip)
    guard thumbTip.isTracked, thumbIntermediate.isTracked else { return false }

    // Thumb must be pointing up (tip higher in Y than intermediate)
    let thumbTipY = thumbTip.anchorFromJointTransform.columns.3.y
    let thumbIntY = thumbIntermediate.anchorFromJointTransform.columns.3.y
    guard thumbTipY > thumbIntY + 0.01 else { return false }

    // Check all other fingers are curled
    let fingerTips: [HandSkeleton.JointName] = [
      .indexFingerTip, .middleFingerTip, .ringFingerTip, .littleFingerTip
    ]
    let fingerIntermediates: [HandSkeleton.JointName] = [
      .indexFingerIntermediateTip, .middleFingerIntermediateTip,
      .ringFingerIntermediateTip, .littleFingerIntermediateTip
    ]

    for (tip, intermediate) in zip(fingerTips, fingerIntermediates) {
      let tipJoint = skeleton.joint(tip)
      let intJoint = skeleton.joint(intermediate)
      guard tipJoint.isTracked, intJoint.isTracked else { return false }

      let tipY = tipJoint.anchorFromJointTransform.columns.3.y
      let intY = intJoint.anchorFromJointTransform.columns.3.y
      // Finger tip should be BELOW intermediate (curled)
      guard tipY < intY else { return false }
    }

    return true
  }
}
#endif
