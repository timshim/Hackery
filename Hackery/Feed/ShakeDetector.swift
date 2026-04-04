//
//  ShakeDetector.swift
//  Hackery
//
//  Created by Claude on 4/4/26.
//  Copyright © 2026 Tim Shim. All rights reserved.
//

#if os(iOS)
import SwiftUI
import UIKit

// MARK: - Shake Notification

extension UIDevice {
  static let shakeNotification = Notification.Name("deviceDidShake")
}

// MARK: - UIWindow override to detect shake

extension UIWindow {
  open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
    super.motionEnded(motion, with: event)
    if motion == .motionShake {
      NotificationCenter.default.post(name: UIDevice.shakeNotification, object: nil)
    }
  }
}

// MARK: - SwiftUI ViewModifier

struct OnShakeModifier: ViewModifier {
  let action: () -> Void

  func body(content: Content) -> some View {
    content
      .onReceive(NotificationCenter.default.publisher(for: UIDevice.shakeNotification)) { _ in
        action()
      }
  }
}

extension View {
  func onShake(perform action: @escaping () -> Void) -> some View {
    modifier(OnShakeModifier(action: action))
  }
}
#endif
