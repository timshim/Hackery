//
//  SafariView.swift
//  HackeryV
//
//  Created by Tim Shim on 6/8/23.
//  Copyright © 2023 Tim Shim. All rights reserved.
//

import SwiftUI

#if os(iOS)
import SafariServices

struct SafariView: View {
  @Environment(\.dismiss) private var dismiss

  var url: URL

  var body: some View {
    SafariViewController(url: url, onDismiss: { dismiss() })
  }
}

struct SafariViewController: UIViewControllerRepresentable {

  var url: URL
  var onDismiss: () -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(onDismiss: onDismiss)
  }

  func makeUIViewController(context: Context) -> SFSafariViewController {
    let safariVC = SFSafariViewController(url: url)
    safariVC.delegate = context.coordinator
    return safariVC
  }

  func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}

  final class Coordinator: NSObject, SFSafariViewControllerDelegate {
    let onDismiss: () -> Void

    init(onDismiss: @escaping () -> Void) {
      self.onDismiss = onDismiss
    }

    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
      onDismiss()
    }
  }
}
#endif
