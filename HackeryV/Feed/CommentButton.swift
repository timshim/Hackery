//
//  CommentButton.swift
//  HackeryV
//
//  Created by Tim Shim on 6/8/23.
//  Copyright © 2023 Tim Shim. All rights reserved.
//

import SwiftUI

struct CommentButton: View {
  var count: Int

  var body: some View {
    Text(verbatim: "\(count > 100 ? "100+" : "\(count)") \(count == 1 ? "COMMENT" : "COMMENTS")")
      .font(.custom("Lato-Regular", size: 13, relativeTo: .callout))
      .foregroundStyle(.secondary)
      .padding()
      .accessibilityLabel("\(count) \(count == 1 ? "comment" : "comments")")
  }
}
