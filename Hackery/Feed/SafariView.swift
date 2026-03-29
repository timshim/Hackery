//
//  SafariView.swift
//  Hackery
//
//  Created by Tim Shim on 31/5/20.
//  Copyright © 2020 Tim Shim. All rights reserved.
//

#if os(iOS)
import SwiftUI
import SafariServices

struct SafariView: View {
  @Environment(\.dismiss) private var dismiss

  var url: URL

  var body: some View {
    SafariViewController(url: url, onDismiss: { dismiss() })
      .ignoresSafeArea()
      .navigationBarTitle("", displayMode: .inline)
      .navigationBarHidden(true)
  }
}

struct SafariViewController: UIViewControllerRepresentable {

  var url: URL
  var onDismiss: () -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(onDismiss: onDismiss)
  }

  func makeUIViewController(context: Context) -> SFSafariViewController {
    let config = SFSafariViewController.Configuration()
    config.entersReaderIfAvailable = true
    let safariVC = SFSafariViewController(url: url, configuration: config)
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

struct PushedSafariView: UIViewControllerRepresentable {
  var url: URL

  func makeUIViewController(context: Context) -> SFSafariViewController {
    let config = SFSafariViewController.Configuration()
    config.entersReaderIfAvailable = true
    return SFSafariViewController(url: url, configuration: config)
  }

  func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
  override open func viewDidLoad() {
    super.viewDidLoad()
    interactivePopGestureRecognizer?.delegate = self
  }

  public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    return viewControllers.count > 1
  }

  public func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    true
  }
}
#endif
