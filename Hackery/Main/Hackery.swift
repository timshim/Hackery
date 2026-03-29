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
  @State private var bookmarkStore = BookmarkStore()
  @State private var currentPage = 1

  var body: some Scene {
    WindowGroup {
      TabView(selection: $currentPage) {
        BookmarksView()
          .tag(0)
        FeedView()
          .tag(1)
      }
      .tabViewStyle(.page(indexDisplayMode: .never))
      .background(Color("background"))
      .ignoresSafeArea()
      .environment(viewModel)
      .environment(bookmarkStore)
    }
  }
}
