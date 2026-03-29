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
  #if os(iOS)
  @Environment(\.isPaging) private var isPaging
  @State private var selectedURL: URL?
  #elseif os(visionOS)
  @State private var selectedStory: Story?
  #endif

  var body: some View {
    NavigationStack {
      ZStack {
        #if os(iOS)
        Color("background")
          .ignoresSafeArea()
        #endif
        if bookmarkStore.bookmarks.isEmpty {
          #if os(iOS)
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
          #elseif os(visionOS)
          ContentUnavailableView(
            "No Bookmarks",
            systemImage: "bookmark",
            description: Text("Stories you bookmark will appear here.")
          )
          #endif
        } else {
          List {
            ForEach(bookmarkStore.bookmarks) { story in
              #if os(iOS)
              StoryView(story: story)
                .contentShape(Rectangle())
                .onTapGesture {
                  if let url = URL(string: story.url), !story.url.isEmpty {
                    selectedURL = url
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
              #elseif os(visionOS)
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
              #endif
            }
          }
          .listStyle(.plain)
          #if os(iOS)
          .scrollContentBackground(.hidden)
          .scrollDisabled(isPaging)
          .fullScreenCover(isPresented: Binding(
            get: { selectedURL != nil },
            set: { if !$0 { selectedURL = nil } }
          )) {
            if let url = selectedURL {
              PushedSafariView(url: url)
                .ignoresSafeArea()
            }
          }
          #elseif os(visionOS)
          .contentMargins(.vertical, 16)
          .sheet(item: $selectedStory) { story in
            CommentsView(story: story)
          }
          #endif
        }
        #if os(iOS)
        StatusBarView()
        #endif
      }
      .navigationBarHidden(true)
    }
  }
}
