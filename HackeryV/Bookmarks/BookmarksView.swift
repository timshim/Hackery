//
//  BookmarksView.swift
//  HackeryV
//
//  Created by Tim Shim on 7/8/23.
//  Copyright © 2023 Tim Shim. All rights reserved.
//

import SwiftUI

struct BookmarksView: View {
  @Environment(BookmarkStore.self) private var bookmarkStore
  @Environment(FeedViewModel.self) private var viewModel

  var body: some View {
    Group {
      if bookmarkStore.bookmarks.isEmpty {
        ContentUnavailableView(
          "No Bookmarks",
          systemImage: "bookmark",
          description: Text("Stories you bookmark will appear here.")
        )
      } else {
        List {
          ForEach(bookmarkStore.bookmarks) { story in
            VStack(alignment: .leading, spacing: 4) {
              Text(story.title)
                .font(.system(.headline, design: .rounded))
              Text("\(story.score) points \u{2022} \(story.by) \u{2022} \(story.timeAgo)")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
            }
            .swipeActions(edge: .trailing) {
              Button(role: .destructive) {
                bookmarkStore.toggle(story)
              } label: {
                Label("Remove", systemImage: "bookmark.slash")
              }
            }
          }
        }
      }
    }
  }
}
