//
//  FeedView.swift
//  Hackery
//
//  Created by Tim Shim on 6/10/19.
//  Copyright © 2019 Tim Shim. All rights reserved.
//

import SwiftUI

struct FeedView: View {
  @Environment(FeedViewModel.self) private var viewModel
  @State private var showGlow = false

  var body: some View {
    NavigationStack {
      ZStack {
        BackgroundView()
        if viewModel.isLoading && viewModel.stories.isEmpty {
          LoaderView()
        }
        StoryListView()
        VStack {
          Spacer()
          PaginationGlow()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .opacity(showGlow ? 1 : 0)
        StatusBarView()
      }
      .navigationBarHidden(true)
      .overlay(alignment: .bottom) {
        RefreshButtonView(tapped: refresh)
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
    .onChange(of: viewModel.isLoadingMore) { _, loading in
      if loading {
        withAnimation(.easeIn(duration: 0.3)) { showGlow = true }
      } else {
        withAnimation(.easeOut(duration: 0.6)) { showGlow = false }
      }
    }
  }

  private func refresh() {
    viewModel.loadTopStories(refresh: true)
  }
}

struct BackgroundView: View {
  var body: some View {
    Color("background")
      .ignoresSafeArea()
  }
}

struct StoryListView: View {
  @Environment(FeedViewModel.self) private var viewModel
  @Environment(BookmarkStore.self) private var bookmarkStore
  @Environment(\.isPaging) private var isPaging

  var body: some View {
    List {
      ForEach(viewModel.stories) { story in
        StoryView(story: story)
          .background {
            if let url = URL(string: story.url), !story.url.isEmpty {
              NavigationLink(destination: SafariView(url: url)) {
                EmptyView()
              }
              .opacity(0)
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
          .tint(bookmarkStore.isBookmarked(story) ? .orange : .teal)
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

      if viewModel.hasMoreStories && !viewModel.stories.isEmpty && !viewModel.isLoading {
        Color.clear
          .frame(height: 1)
          .listRowBackground(Color.clear)
          .listRowSeparator(.hidden)
          .onAppear {
            Task { await viewModel.loadMoreStories() }
          }
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .scrollDisabled(isPaging)
  }
}

struct StatusBarView: View {
  var body: some View {
    GeometryReader { proxy in
      Color("background")
        .frame(maxWidth: .infinity)
        .frame(height: proxy.safeAreaInsets.top)
        .ignoresSafeArea()
    }
  }
}

struct RefreshButtonView: View {
  var tapped: (() -> Void)?

  var body: some View {
    VStack {
      Spacer()
      Button(action: {
        tapped?()
      }) {
        Image(systemName: "arrow.clockwise")
          .font(.system(size: 24, weight: .bold, design: .rounded))
          .foregroundColor(Color("titleColor"))
          .padding(.bottom, 6)
      }
      .frame(width: 60, height: 60)
      .glassEffect(.clear)
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

struct LoaderView: View {
  var body: some View {
    VStack {
      Spacer()
      ProgressView()
      Spacer()
    }
    .ignoresSafeArea()
  }
}

struct ErrorBannerView: View {
  let message: String

  var body: some View {
    Text(message)
      .font(.custom("Lato-Regular", size: 14, relativeTo: .footnote))
      .foregroundColor(.white)
      .padding()
      .background(Color.red.opacity(0.85), in: RoundedRectangle(cornerRadius: 12))
      .padding()
      .transition(.move(edge: .bottom).combined(with: .opacity))
  }
}
