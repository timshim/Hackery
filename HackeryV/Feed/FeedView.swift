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

  var body: some View {
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
    .ornament(attachmentAnchor: .scene(.bottom), ornament: {
      RefreshButtonView(tapped: refresh)
        .glassBackgroundEffect()
    })
    .onAppear {
      viewModel.loadTopStories()
    }
  }

  private func refresh() {
    viewModel.loadTopStories(refresh: true)
  }
}

struct StoryListView: View {
  @Environment(FeedViewModel.self) private var viewModel
  @Environment(BookmarkStore.self) private var bookmarkStore

  var body: some View {
    List {
      ForEach(viewModel.stories) { story in
        StoryView(story: story)
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
            .tint(.orange)
          }
          .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
      }

      if viewModel.hasMoreStories {
        ProgressView()
          .frame(maxWidth: .infinity)
          .padding()
          .listRowSeparator(.hidden)
          .onAppear {
            Task { await viewModel.loadMoreStories() }
          }
      }
    }
    .listStyle(.plain)
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
