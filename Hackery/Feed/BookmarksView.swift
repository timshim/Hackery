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
  @Environment(\.horizontalSizeClass) private var sizeClass
  @Environment(StoryPresenter.self) private var presenter: StoryPresenter?
  @Environment(\.storyListPlacement) private var placement
  @State private var selectedURL: URL?
  @State private var rowFrames = StoryRowFrames()
  #elseif os(visionOS)
  @State private var selectedStory: Story?
  #endif

  var body: some View {
    #if os(iOS)
    // Shares the navigation container, and its bar, with the feed page.
    content
    #elseif os(visionOS)
    NavigationStack {
      content
        .navigationBarHidden(true)
    }
    #endif
  }

  private var content: some View {
    ZStack {
      #if os(iOS)
      Color("background")
        .ignoresSafeArea()
      #endif
      if bookmarkStore.bookmarks.isEmpty {
        emptyState
      } else {
        #if os(iOS)
        if sizeClass == .regular && presenter == nil {
          iPadGrid
        } else {
          phoneList
        }
        #elseif os(visionOS)
        visionList
        #endif
      }
      #if os(iOS)
      StatusBarView()
      #endif
    }
  }

  // MARK: - Empty State

  private var emptyState: some View {
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
  }

  // MARK: - iPad Masonry Grid

  #if os(iOS)
  private var iPadGrid: some View {
    ScrollView {
      MasonryLayout(columns: 3, spacing: 10) {
        ForEach(bookmarkStore.bookmarks) { story in
          StoryView(story: story)
            .background(
              RoundedRectangle(cornerRadius: 16)
                .fill(Color("cardBg"))
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .contentShape(Rectangle())
            .onTapGesture {
              if let url = URL(string: story.url), !story.url.isEmpty {
                selectedURL = url
              }
            }
            .contextMenu {
              Button(role: .destructive, action: { bookmarkStore.toggle(story) }) {
                Label("Remove Bookmark", systemImage: "bookmark.slash.fill")
              }
            }
        }
      }
      .padding(.horizontal, 12)
      .padding(.top, 8)
    }
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
  }

  // MARK: - iPhone List

  private var phoneList: some View {
    List {
      ForEach(bookmarkStore.bookmarks) { story in
        StoryView(story: story)
          .contentShape(Rectangle())
          .onTapGesture {
            if let presenter {
              presenter.show(story, mode: .article)
            } else if let url = URL(string: story.url), !story.url.isEmpty {
              selectedURL = url
            }
          }
          .reportsStoryRowFrame(story.id, to: rowFrames)
          .listRowBackground(
            RoundedRectangle(cornerRadius: 16)
              .fill(Color("cardBg"))
              .padding(.vertical, 1)
              .padding(.leading, placement.leadingCardInset)
              .padding(.trailing, placement.trailingCardInset)
          )
          .listRowSeparator(.hidden)
          .listRowInsets(EdgeInsets(
            top: 1, leading: placement.leadingCardInset, bottom: 1, trailing: placement.trailingCardInset))
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .scrollDisabled(isPaging)
    .overlay {
      if let presenter, placement == .besidePane {
        SelectionIndicatorOverlay(rowFrames: rowFrames, selectedID: presenter.story?.id)
      }
    }
    .frame(maxWidth: placement.maxWidth)
    .fullScreenCover(isPresented: Binding(
      get: { selectedURL != nil },
      set: { if !$0 { selectedURL = nil } }
    )) {
      if let url = selectedURL {
        PushedSafariView(url: url)
          .ignoresSafeArea()
      }
    }
  }
  #endif

  // MARK: - visionOS List

  #if os(visionOS)
  private var visionList: some View {
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
  #endif
}
