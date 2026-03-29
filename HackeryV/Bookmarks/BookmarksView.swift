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
  @State private var selectedStory: Story?

  var body: some View {
    NavigationStack {
      ZStack {
        if bookmarkStore.bookmarks.isEmpty {
          ContentUnavailableView(
            "No Bookmarks",
            systemImage: "bookmark",
            description: Text("Stories you bookmark will appear here.")
          )
        } else {
          List {
            ForEach(bookmarkStore.bookmarks) { story in
              StoryView(story: story, onShowComments: { selectedStory = story })
                .contentShape(.hoverEffect, .rect(cornerRadius: 16))
                .hoverEffect()
                .onTapGesture {
                  if let url = URL(string: story.url), !story.url.isEmpty {
                    UIApplication.shared.open(url)
                  }
                }
                .swipeActions(edge: .trailing) {
                  Button(role: .destructive) {
                    bookmarkStore.toggle(story)
                  } label: {
                    Label("Remove", systemImage: "bookmark.slash")
                  }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
            }
          }
          .listStyle(.plain)
          .contentMargins(.vertical, 16)
          .sheet(item: $selectedStory) { story in
            CommentsView(story: story)
          }
        }
      }
    }
  }
}
