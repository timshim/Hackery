//
//  HandTrackingManagerTests.swift
//  HackeryTests
//
//  Created by Claude on 4/4/26.
//  Copyright © 2026 Tim Shim. All rights reserved.
//

import Testing
import Foundation
@testable import Hackery

struct HandTrackingManagerTests {

  #if os(visionOS)
  @Test func initialStateIsNotDetected() {
    let manager = HandTrackingManager()
    #expect(manager.thumbsUpDetected == false)
  }

  @Test func resetDetectionClearsState() {
    let manager = HandTrackingManager()
    manager.resetDetection()
    #expect(manager.thumbsUpDetected == false)
  }

  @Test func isAvailableReflectsHardwareSupport() {
    let manager = HandTrackingManager()
    // In simulator this will be false, on device it depends on hardware
    // Just verify it doesn't crash and returns a boolean
    let _ = manager.isAvailable
  }
  #endif
}
