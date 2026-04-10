//
//  DeepLinkRouter.swift
//  Hackery
//
//  Parses hackery:// URLs and NSUserActivity payloads from Spotlight /
//  widgets / the share extension into a pending navigation intent the UI
//  can observe and act on.
//

import Foundation
import SwiftUI
import CoreSpotlight

enum DeepLinkDestination: Equatable {
  case story(id: Int)
  case bookmarks
}

@MainActor
@Observable
final class DeepLinkRouter {
  var pending: DeepLinkDestination?

  /// Handles URLs of the form:
  ///   hackery://story/12345
  ///   hackery://bookmarks
  func handle(url: URL) {
    guard url.scheme == "hackery" else { return }
    let host = url.host?.lowercased()
    let segments = url.pathComponents.filter { $0 != "/" }

    switch host {
    case "story":
      if let first = segments.first, let id = Int(first) {
        pending = .story(id: id)
      }
    case "bookmarks":
      pending = .bookmarks
    default:
      break
    }
  }

  /// Handles NSUserActivity from Spotlight results. The activity's
  /// `uniqueIdentifier` is a `hackery://story/{id}` URL string.
  func handle(activity: NSUserActivity) {
    if activity.activityType == CSSearchableItemActionType,
       let idString = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
       let url = URL(string: idString) {
      handle(url: url)
    }
  }

  func clear() { pending = nil }
}
