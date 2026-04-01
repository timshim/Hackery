//
//  ReportService.swift
//  Hackery
//
//  Created by Tim Shim on 31/3/26.
//  Copyright © 2026 Tim Shim. All rights reserved.
//

import Foundation

enum ReportService {
  /// Reports a comment to the backend server.
  /// Currently a stub — backend URL to be configured later.
  static func report(comment: Comment, reason: String) async {
    // TODO: Replace with actual backend call
    // Simulated network delay for testing
    try? await Task.sleep(for: .seconds(1.5))
    print("[ReportService] Report submitted — comment \(comment.id) by \(comment.by): \(reason)")
  }
}
