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
  #if os(visionOS)
  @State private var showBookmarks = false
  #endif

  var body: some View {
    #if os(iOS)
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
    #elseif os(visionOS)
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
    #endif
  }

  private func refresh() {
    viewModel.loadTopStories(refresh: true)
  }
}

// MARK: - Story List

struct StoryListView: View {
  @Environment(FeedViewModel.self) private var viewModel
  @Environment(BookmarkStore.self) private var bookmarkStore
  #if os(iOS)
  @Environment(\.isPaging) private var isPaging
  @State private var selectedURL: URL?
  #elseif os(visionOS)
  @State private var selectedStory: Story?
  #endif

  var body: some View {
    List {
      ForEach(viewModel.stories) { story in
        #if os(iOS)
        storyRow(story)
          .swipeActions(edge: .trailing) {
            bookmarkSwipeButton(story)
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
        storyRow(story)
          .contentShape(.hoverEffect, .rect(cornerRadius: 16))
          .hoverEffect()
          .swipeActions(edge: .trailing) {
            bookmarkSwipeButton(story)
          }
          .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
        #endif
      }

      if viewModel.hasMoreStories && !viewModel.stories.isEmpty && !viewModel.isLoading {
        Color.clear
          .frame(height: 1)
          .listRowSeparator(.hidden)
          #if os(iOS)
          .listRowBackground(Color.clear)
          #endif
          .onAppear {
            Task { await viewModel.loadMoreStories() }
          }
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

  private func storyRow(_ story: Story) -> some View {
    #if os(iOS)
    StoryView(story: story)
      .contentShape(Rectangle())
      .onTapGesture {
        if let url = URL(string: story.url), !story.url.isEmpty {
          selectedURL = url
        }
      }
    #elseif os(visionOS)
    StoryView(story: story, onShowComments: { selectedStory = story })
      .onTapGesture {
        if let url = URL(string: story.url), !story.url.isEmpty {
          UIApplication.shared.open(url)
        }
      }
    #endif
  }

  private func bookmarkSwipeButton(_ story: Story) -> some View {
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
}

// MARK: - Shared Views

struct RefreshButtonView: View {
  var tapped: (() -> Void)?

  var body: some View {
    #if os(iOS)
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
    #elseif os(visionOS)
    Button(action: {
      tapped?()
    }) {
      Image(systemName: "arrow.clockwise")
        .font(.system(size: 24, weight: .bold, design: .rounded))
        .frame(width: 60, height: 60)
        .padding()
    }
    .buttonStyle(.plain)
    #endif
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
    #if os(iOS)
    .ignoresSafeArea()
    #endif
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

// MARK: - iOS Only Views

#if os(iOS)
struct BackgroundView: View {
  var body: some View {
    Color("background")
      .ignoresSafeArea()
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
#endif
