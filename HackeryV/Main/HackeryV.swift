//
//  HackeryV.swift
//  HackeryV
//
//  Created by Tim Shim on 6/8/23.
//  Copyright © 2023 Tim Shim. All rights reserved.
//

import SwiftUI
import SwiftData

@main
struct HackeryV: App {
  @State private var viewModel = FeedViewModel()

  private let modelContainer: ModelContainer
  @State private var bookmarkStore: BookmarkStore
  @State private var showGlow = false

  init() {
    let schema = Schema([BookmarkedStory.self])
    let container: ModelContainer
    do {
      let config = ModelConfiguration(
        "Bookmarks",
        schema: schema,
        cloudKitDatabase: .automatic
      )
      container = try ModelContainer(for: schema, configurations: [config])
    } catch {
      let config = ModelConfiguration(
        "Bookmarks",
        schema: schema,
        cloudKitDatabase: .none
      )
      container = try! ModelContainer(for: schema, configurations: [config])
    }
    self.modelContainer = container
    self._bookmarkStore = State(initialValue: BookmarkStore(modelContext: container.mainContext))
  }

  var body: some Scene {
    WindowGroup {
      ZStack {
        FeedView()
          .frame(minWidth: 500, maxWidth: 500)
          .padding()
          .environment(viewModel)
          .environment(bookmarkStore)
        VStack {
          Spacer()
          PaginationGlow()
        }
        .allowsHitTesting(false)
        .opacity(showGlow ? 1 : 0)
      }
      .onChange(of: viewModel.isLoadingMore) { _, loading in
        if loading {
          withAnimation(.easeIn(duration: 0.3)) { showGlow = true }
        } else {
          withAnimation(.easeOut(duration: 0.6)) { showGlow = false }
        }
      }
    }
    .defaultSize(width: 500, height: 800)
    .windowResizability(.contentSize)
  }
}
