//
//  HackeryV.swift
//  HackeryV
//
//  Created by Tim Shim on 6/8/23.
//  Copyright © 2023 Tim Shim. All rights reserved.
//

import SwiftUI

@main
struct HackeryV: App {
  @State private var viewModel = FeedViewModel()

  var body: some Scene {
    WindowGroup {
      FeedView()
        .frame(minWidth: 500, maxWidth: 500)
        .padding()
        .environment(viewModel)
    }
    .defaultSize(width: 500, height: 800)
    .windowResizability(.contentSize)
  }
}
