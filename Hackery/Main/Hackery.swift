//
//  AppDelegate.swift
//  Hackery
//
//  Created by Tim Shim on 6/10/19.
//  Copyright © 2019 Tim Shim. All rights reserved.
//

import SwiftUI

@main
struct Hackery: App {
  @State private var viewModel = FeedViewModel()

  var body: some Scene {
    WindowGroup {
      FeedView().environment(viewModel)
    }
  }
}
