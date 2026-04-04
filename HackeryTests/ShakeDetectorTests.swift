//
//  ShakeDetectorTests.swift
//  HackeryTests
//
//  Created by Claude on 4/4/26.
//  Copyright © 2026 Tim Shim. All rights reserved.
//

import Testing
import Foundation
@testable import Hackery

struct ShakeDetectorTests {

  @Test func shakeNotificationNameExists() {
    #if os(iOS)
    let name = UIDevice.shakeNotification
    #expect(name.rawValue == "deviceDidShake")
    #endif
  }

  @Test func shakeNotificationFires() async {
    #if os(iOS)
    await confirmation { confirm in
      let observer = NotificationCenter.default.addObserver(
        forName: UIDevice.shakeNotification,
        object: nil,
        queue: .main
      ) { _ in
        confirm()
      }
      NotificationCenter.default.post(name: UIDevice.shakeNotification, object: nil)
      NotificationCenter.default.removeObserver(observer)
    }
    #endif
  }
}
