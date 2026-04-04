//
//  FeedView.swift
//  HackeryV
//
//  Created by Tim Shim on 6/8/23.
//  Copyright © 2023 Tim Shim. All rights reserved.
//

import SwiftUI

struct FeedView: View {
  @Environment(FeedViewModel.self) private var viewModel
  @State private var showBookmarks = false

  var body: some View {
    Group {
      if showBookmarks {
        BookmarksView()
      } else {
        NavigationStack {
          ZStack {
            if viewModel.isLoading && viewModel.stories.isEmpty {
              LoaderView()
            }
            StoryListView()
          }
          .overlay(alignment: .bottom) {
            if let error = viewModel.error {
              ErrorBannerView(message: error)
            }
          }
        }
        .onAppear {
          viewModel.loadTopStories()
        }
      }
    }
    .ornament(attachmentAnchor: .scene(.bottom), ornament: {
      HStack(spacing: 12) {
        Button(action: {
          withAnimation(.easeInOut(duration: 0.2)) { showBookmarks.toggle() }
        }) {
          Image(systemName: showBookmarks ? "list.bullet" : "bookmark.fill")
            .font(.system(size: 24, weight: .bold, design: .rounded))
            .frame(width: 60, height: 60)
            .padding()
        }
        .buttonStyle(.plain)

        if !showBookmarks {
          RefreshButtonView(tapped: refresh)
        }
      }
      .padding(.horizontal, 8)
      .glassBackgroundEffect()
    })
  }

  private func refresh() {
    viewModel.loadTopStories(refresh: true)
  }
}

struct StoryListView: View {
  @Environment(FeedViewModel.self) private var viewModel
  @Environment(BookmarkStore.self) private var bookmarkStore
  @State private var selectedStory: Story?

  var body: some View {
    List {
      ForEach(viewModel.stories) { story in
        StoryView(story: story, onShowComments: { selectedStory = story })
          .contentShape(.hoverEffect, .rect(cornerRadius: 16))
          .hoverEffect()
          .onTapGesture {
            if let url = URL(string: story.url), !story.url.isEmpty {
              UIApplication.shared.open(url)
            }
          }
          .swipeActions(edge: .trailing) {
            Button(action: {
              bookmarkStore.toggle(story)
            }) {
              Label(
                bookmarkStore.isBookmarked(story) ? "Unbookmark" : "Bookmark",
                systemImage: bookmarkStore.isBookmarked(story) ? "bookmark.slash.fill" : "bookmark.fill"
              )
            }
            .tint(bookmarkStore.isBookmarked(story) ? Color("accentOrange") : .teal)
          }
          .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
      }

      if viewModel.hasMoreStories && !viewModel.stories.isEmpty && !viewModel.isLoading {
        Color.clear
          .frame(height: 1)
          .listRowSeparator(.hidden)
          .onAppear {
            Task { await viewModel.loadMoreStories() }
          }
      }
    }
    .listStyle(.plain)
    .contentMargins(.vertical, 16)
    .sheet(item: $selectedStory) { story in
      CommentsView(story: story)
    }
  }
}

struct RefreshButtonView: View {
  var tapped: (() -> Void)?

  var body: some View {
    Button(action: {
      tapped?()
    }) {
      Image(systemName: "arrow.clockwise")
        .font(.system(size: 24, weight: .bold, design: .rounded))
        .frame(width: 60, height: 60)
        .padding()
    }
    .buttonStyle(.plain)
  }
}

struct LoaderView: View {
  var body: some View {
    VStack {
      Spacer()
      ProgressView()
      Spacer()
    }
  }
}

struct PaginationGlow: View {
  @State private var pulse = false

  var body: some View {
    LinearGradient(
      colors: [
        Color.clear,
        Color.blue.opacity(pulse ? 0.3 : 0.1),
        Color.purple.opacity(pulse ? 0.25 : 0.08)
      ],
      startPoint: .top,
      endPoint: .bottom
    )
    .frame(height: 160)
    .animation(
      .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
      value: pulse
    )
    .onAppear { pulse = true }
  }
}

struct ErrorBannerView: View {
  let message: String

  var body: some View {
    Text(message)
      .font(.system(.footnote, design: .rounded))
      .foregroundColor(.white)
      .padding()
      .background(Color.red.opacity(0.85), in: RoundedRectangle(cornerRadius: 12))
      .padding()
      .transition(.move(edge: .bottom).combined(with: .opacity))
  }
}
