//
//  BookmarksView.swift
//  Hackery
//
//  Created by Tim Shim on 29/3/26.
//  Copyright © 2026 Tim Shim. All rights reserved.
//

import SwiftUI

struct BookmarksView: View {
  @Environment(BookmarkStore.self) private var bookmarkStore
  @Environment(\.isPaging) private var isPaging

  var body: some View {
    NavigationStack {
      ZStack {
        Color("background")
          .ignoresSafeArea()
        if bookmarkStore.bookmarks.isEmpty {
          VStack(spacing: 8) {
            Image(systemName: "bookmark")
              .font(.system(size: 36))
              .foregroundColor(Color("subtitleColor"))
            Text("No Bookmarks")
              .font(.custom("Lato-Bold", size: 18, relativeTo: .headline))
              .foregroundColor(Color("titleColor"))
            Text("Swipe left on a story to bookmark it.")
              .font(.custom("Lato-Regular", size: 14, relativeTo: .caption))
              .foregroundColor(Color("subtitleColor"))
          }
        } else {
          List {
            ForEach(bookmarkStore.bookmarks) { story in
              StoryView(story: story)
                .background {
                  if let url = URL(string: story.url), !story.url.isEmpty {
                    NavigationLink(destination: SafariView(url: url)) {
                      EmptyView()
                    }
                    .opacity(0)
                  }
                }
                .listRowBackground(
                  RoundedRectangle(cornerRadius: 16)
                    .fill(Color("cardBg"))
                    .padding(.vertical, 1)
                    .padding(.horizontal, 8)
                )
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 1, leading: 8, bottom: 1, trailing: 8))
            }
          }
          .listStyle(.plain)
          .scrollContentBackground(.hidden)
          .scrollDisabled(isPaging)
        }
        StatusBarView()
      }
      .navigationBarHidden(true)
    }
  }
}
