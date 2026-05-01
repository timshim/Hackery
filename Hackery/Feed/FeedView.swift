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
  @Environment(EngagementTracker.self) private var engagement
  @State private var showGlow = false
  @State private var showTipJar = false
  @State private var showReviewPrompt = false
  #if os(visionOS)
  @State private var showBookmarks = false
  #endif

  var body: some View {
    #if os(iOS)
    // Shares the navigation container, and its bar, with the bookmarks page.
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
    .modifier(FloatingRefresh(refresh: refresh))
    .overlay(alignment: .bottom) {
      if let error = viewModel.error {
        ErrorBannerView(message: error)
      }
    }
    .onAppear {
      viewModel.loadTopStories()
    }
    .onShake { showTipJar = true }
    .sheet(isPresented: $showTipJar) {
      TipJarView()
    }
    .alert("Enjoying Hackery?", isPresented: $showReviewPrompt) {
      Button("Yes 👍") {
        engagement.promptShown()
        engagement.requestReview()
      }
      Button("Not really", role: .cancel) {
        engagement.promptShown()
      }
    } message: {
      Text("Support me by rating it on the App Store! It only takes a second.")
    }
    .onChange(of: engagement.pendingPrompt) { _, prompt in
      guard prompt != nil else { return }
      checkEngagementPrompt()
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
    .sheet(isPresented: $showTipJar) {
      TipJarView()
    }
    .alert("Enjoying Hackery?", isPresented: $showReviewPrompt) {
      Button("Yes 👍") {
        engagement.promptShown()
        engagement.requestReview()
      }
      Button("Not really", role: .cancel) {
        engagement.promptShown()
      }
    } message: {
      Text("Support me by rating it on the App Store! It only takes a second.")
    }
    .onChange(of: engagement.pendingPrompt) { _, prompt in
      guard prompt != nil else { return }
      checkEngagementPrompt()
    }
    #endif
  }

  private func checkEngagementPrompt() {
    switch engagement.pendingPrompt {
    case .review:
      showReviewPrompt = true
    case .tipJar:
      engagement.promptShown()
      showTipJar = true
    case nil:
      break
    }
  }

  private func refresh() {
    viewModel.loadTopStories(refresh: true)
  }
}

// MARK: - Story List

struct StoryListView: View {
  @Environment(FeedViewModel.self) private var viewModel
  @Environment(BookmarkStore.self) private var bookmarkStore
  @Environment(EngagementTracker.self) private var engagement
  #if os(visionOS)
  @Environment(BlocklistStore.self) private var blocklistStore
  #endif
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
    // Beside a detail pane the list is a single column, whatever the width.
    if sizeClass == .regular && presenter == nil {
      masonryGrid
    } else {
      phoneList
    }
    #elseif os(visionOS)
    visionList
    #endif
  }

  // MARK: - iPad Masonry Grid

  #if os(iOS)
  private var masonryGrid: some View {
    ScrollView {
      MasonryLayout(columns: 3, spacing: 10) {
        ForEach(viewModel.stories) { story in
          storyCard(story)
        }
      }
      .padding(.horizontal, 12)
      .padding(.top, 8)

      if viewModel.hasMoreStories && !viewModel.stories.isEmpty && !viewModel.isLoading {
        Color.clear
          .frame(height: 1)
          .onAppear {
            Task { await viewModel.loadMoreStories() }
          }
      }
    }
    .scrollContentBackground(.hidden)
    .scrollDisabled(isPaging)
    .fullScreenCover(isPresented: Binding(
      get: { selectedURL != nil },
      set: { if !$0 { selectedURL = nil } }
    ), onDismiss: {
      engagement.checkForPrompt()
    }) {
      if let url = selectedURL {
        PushedSafariView(url: url)
          .ignoresSafeArea()
      }
    }
  }

  private func storyCard(_ story: Story) -> some View {
    StoryView(story: story)
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(Color("cardBg"))
      )
      .clipShape(RoundedRectangle(cornerRadius: 16))
      .contentShape(Rectangle())
      .onTapGesture {
        if let url = URL(string: story.url), !story.url.isEmpty {
          engagement.recordInteraction()
          selectedURL = url
        }
      }
      .contextMenu {
        if bookmarkStore.isBookmarked(story) {
          Button(action: { bookmarkStore.toggle(story) }) {
            Label("Remove Bookmark", systemImage: "bookmark.slash.fill")
          }
        } else {
          Button(action: { bookmarkStore.toggle(story) }) {
            Label("Bookmark", systemImage: "bookmark.fill")
          }
        }
      }
  }

  // MARK: - iPhone List

  private var phoneList: some View {
    List {
      ForEach(viewModel.stories) { story in
        storyRow(story)
          .reportsStoryRowFrame(story.id, to: rowFrames)
          .swipeActions(edge: .trailing) {
            bookmarkSwipeButton(story)
          }
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

      if viewModel.hasMoreStories && !viewModel.stories.isEmpty && !viewModel.isLoading {
        Color.clear
          .frame(height: 1)
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
          .onAppear {
            Task { await viewModel.loadMoreStories() }
          }
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
    ), onDismiss: {
      engagement.checkForPrompt()
    }) {
      if let url = selectedURL {
        PushedSafariView(url: url)
          .ignoresSafeArea()
      }
    }
  }
  #endif

  // MARK: - visionOS List

  #if os(visionOS)
  private var visionStories: [Story] {
    viewModel.stories.filter { !blocklistStore.isBlocked($0) }
  }

  private var visionList: some View {
    List {
      ForEach(visionStories) { story in
        storyRow(story)
          .contentShape(.hoverEffect, .rect(cornerRadius: 16))
          .hoverEffect()
          .swipeActions(edge: .trailing) {
            bookmarkSwipeButton(story)
          }
          .swipeActions(edge: .leading) {
            Button(role: .destructive, action: {
              withAnimation { blocklistStore.block(story) }
            }) {
              Label("Hide", systemImage: "eye.slash.fill")
            }
            .tint(.red)
          }
          .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
      }

      if viewModel.hasMoreStories && !viewModel.stories.isEmpty && !viewModel.isLoading {
        Color.clear
          .frame(height: 1)
          .onAppear {
            Task { await viewModel.loadMoreStories() }
          }
      }
    }
    .listStyle(.plain)
    .contentMargins(.vertical, 16)
    .sheet(item: $selectedStory, onDismiss: {
      engagement.checkForPrompt()
    }) { story in
      CommentsView(story: story)
    }
  }
  #endif

  private func storyRow(_ story: Story) -> some View {
    #if os(iOS)
    StoryView(story: story)
      .contentShape(Rectangle())
      .onTapGesture {
        if let presenter {
          engagement.recordInteraction()
          presenter.show(story, mode: .article)
        } else if let url = URL(string: story.url), !story.url.isEmpty {
          engagement.recordInteraction()
          selectedURL = url
        }
      }
    #elseif os(visionOS)
    StoryView(story: story, onShowComments: { selectedStory = story })
      .onTapGesture {
        if let url = URL(string: story.url), !story.url.isEmpty {
          engagement.recordInteraction()
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
    .tint(bookmarkStore.isBookmarked(story) ? Color.accentColor : .teal)
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

/// Bar controls for the story lists. When the system runs bars down the side
/// of the display, refresh takes the top slot below the status bar, where a
/// back button would sit, and the detail pane's article/comments switch takes
/// the bottom. Otherwise the bar stays hidden; see `FloatingRefresh`.
struct StoryListBarItems: ViewModifier {
  let refresh: () -> Void

  func body(content: Content) -> some View {
    if #available(iOS 27.1, *) {
      content.modifier(VerticalStoryListBarItems(refresh: refresh))
    } else {
      content.navigationBarHidden(true)
    }
  }
}

/// The feed's refresh button, floating over the list when there's no vertical
/// bar to hold it.
struct FloatingRefresh: ViewModifier {
  let refresh: () -> Void

  func body(content: Content) -> some View {
    if #available(iOS 27.1, *) {
      content.modifier(VerticalBarAwareFloatingRefresh(refresh: refresh))
    } else {
      content.overlay(alignment: .bottom) {
        RefreshButtonView(tapped: refresh)
      }
    }
  }
}

@available(iOS 27.1, *)
private struct VerticalBarAwareFloatingRefresh: ViewModifier {
  @Environment(\.toolbarVerticalEdge) private var verticalEdge
  let refresh: () -> Void

  func body(content: Content) -> some View {
    content.overlay(alignment: .bottom) {
      if verticalEdge == nil {
        RefreshButtonView(tapped: refresh)
      }
    }
  }
}

@available(iOS 27.1, *)
private struct VerticalStoryListBarItems: ViewModifier {
  @Environment(\.toolbarVerticalEdge) private var verticalEdge
  @Environment(StoryPresenter.self) private var presenter: StoryPresenter?
  let refresh: () -> Void

  // The bar sizes symbols itself and ignores font modifiers, and at its size
  // the open arrow reads smaller and lighter than the safari and bubble
  // glyphs below it. A configured image is the one thing it respects.
  private static let refreshImage = UIImage(
    systemName: "arrow.clockwise",
    withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold))!

  // Text posts only have comments, so there's nothing to switch between.
  private var showsModeSwitch: Bool {
    guard let story = presenter?.story else { return false }
    return !story.url.isEmpty
  }

  func body(content: Content) -> some View {
    content
      .navigationBarHidden(verticalEdge == nil)
      .toolbar {
        ToolbarItem(placement: .navigation) {
          Button(action: refresh) {
            Label {
              Text("Refresh")
            } icon: {
              Image(uiImage: Self.refreshImage)
            }
          }
          .tint(Color("titleColor"))
        }
        if let presenter, showsModeSwitch, verticalEdge != nil {
          ToolbarItemGroup(placement: .bottomBar) {
            modeButton("Article", systemImage: "safari", mode: .article, presenter: presenter)
            modeButton("Comments", systemImage: "text.bubble", mode: .comments, presenter: presenter)
          }
        }
      }
  }

  private func modeButton(_ title: String, systemImage: String, mode: StoryPresenter.Mode, presenter: StoryPresenter) -> some View {
    let isSelected = presenter.mode == mode
    return Button(action: { presenter.mode = mode }) {
      Label(title, systemImage: systemImage)
    }
    .symbolVariant(isSelected ? .fill : .none)
    .tint(Color("titleColor"))
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}

/// Marks the story open in the detail pane, pointing across to it from the
/// gutter to the left of its card.
struct SelectionIndicator: View {
  static let gutterWidth: CGFloat = 18

  var body: some View {
    Image(systemName: "chevron.left")
      .font(.system(size: 12, weight: .bold))
      .foregroundStyle(.primary)
      .frame(width: Self.gutterWidth)
      .accessibilityHidden(true)
  }
}

/// Where each visible story row sits on screen. The selection indicator is
/// drawn once over the list from these, rather than in every row, so it can
/// travel between rows when the selection changes. Frames are global because
/// list rows don't see coordinate spaces named on the list itself.
@MainActor
@Observable
final class StoryRowFrames {
  var frames: [Int: CGRect] = [:]
}

extension View {
  func reportsStoryRowFrame(_ id: Int, to rowFrames: StoryRowFrames) -> some View {
    onGeometryChange(for: CGRect.self) { proxy in
      proxy.frame(in: .global)
    } action: { frame in
      rowFrames.frames[id] = frame
    }
    .onDisappear { rowFrames.frames[id] = nil }
  }
}

/// The selection indicator for a list, springing to the selected row when the
/// selection changes and following it exactly while the list scrolls.
struct SelectionIndicatorOverlay: View {
  let rowFrames: StoryRowFrames
  let selectedID: Int?

  var body: some View {
    GeometryReader { proxy in
      let origin = proxy.frame(in: .global).origin
      if let selectedID, let frame = rowFrames.frames[selectedID] {
        SelectionIndicator()
          .position(
            x: frame.minX - origin.x - SelectionIndicator.gutterWidth / 2,
            y: frame.midY - origin.y)
          .transition(.opacity)
      }
    }
    // Keyed to the selection only, so scrolling moves the indicator without
    // any animation lag.
    .animation(.spring(duration: 0.35, bounce: 0.2), value: selectedID)
    .clipped()
    .allowsHitTesting(false)
  }
}

/// The column beside the story list on the inner display. Shows the selected
/// story's article or comments in a card; the switch between them lives in
/// the vertical bar, set up by `StoryListBarItems`.
struct StoryDetailPane: View {
  @Environment(StoryPresenter.self) private var presenter
  @State private var showTipJar = false

  /// Set when the pane is open over the list, as a modal, rather than beside
  /// it. Safari's own close button takes it back to the list.
  var isModal = false
  /// Set when there's no vertical bar to hold the article/comments switch.
  var showsModeSwitch = false
  /// The height of the status bar area the switch shares.
  var statusBarInset: CGFloat = 0
  /// The edge of the card that meets the hinge, kept close to it.
  var hingeEdge: Edge?

  var body: some View {
    ZStack {
      Color("background")
        .ignoresSafeArea()
      if let story = presenter.story {
        Group {
          if showsModeSwitch {
            // The buttons share the status bar row, beside the status items,
            // so the card can reach almost to the top.
            VStack(spacing: 0) {
              // Centered in the whole space above the card, which lines it up
              // with the status items.
              header(story)
                .frame(height: max(statusBarInset, 44) + 4)
              card(story)
            }
            .ignoresSafeArea(.container, edges: .top)
          } else {
            card(story)
              .padding(.top, 12)
          }
        }
        // A new story replaces the whole card, and the old one fades away.
        // The new one goes in at full opacity: Safari added while fading in
        // often never starts loading, leaving a blank page.
        .id(story.id)
        .transition(.asymmetric(insertion: .identity, removal: .opacity))
      } else if !isModal {
        // Only reached once a story is closed, since opening the device
        // shows the top story, so use the room to ask for support.
        VStack(spacing: 12) {
          Image(systemName: "cup.and.heat.waves.fill")
            .font(.system(size: 44))
            .foregroundColor(Color("titleColor"))
          Text("Enjoying Hackery?")
            .font(.custom("Lato-Bold", size: 22, relativeTo: .title2))
            .foregroundColor(Color("titleColor"))
          Text("If it's become part of your reading, consider buying me a coffee.")
            .font(.custom("Lato-Regular", size: 15, relativeTo: .subheadline))
            .foregroundColor(Color("subtitleColor"))
            .multilineTextAlignment(.center)
            .frame(maxWidth: 300)
          Button(action: { showTipJar = true }) {
            Text("Buy me a coffee")
              .font(.custom("Lato-Bold", size: 17, relativeTo: .headline))
              .foregroundStyle(.white)
              .padding(.horizontal, 28)
              .padding(.vertical, 14)
              .background(Color.green, in: Capsule())
          }
          .buttonStyle(.plain)
          .padding(.top, 8)
        }
        .padding(24)
        .transition(.opacity)
      }
    }
    .animation(.easeInOut(duration: 0.25), value: presenter.story?.id)
    .animation(.easeInOut(duration: 0.2), value: presenter.mode)
    // A small card over this pane rather than a sheet, which on this display
    // would rise from the bottom much bigger than the tip jar needs.
    .overlay {
      if showTipJar {
        TipJarView(onClose: { showTipJar = false })
          .transition(.opacity)
      }
    }
    .animation(.easeInOut(duration: 0.2), value: showTipJar)
  }

  private func card(_ story: Story) -> some View {
    ZStack {
      // Kept alive under the comments so switching back doesn't reload
      // the page or lose its scroll position.
      if let url = URL(string: story.url), !story.url.isEmpty {
        SafariViewController(url: url, topInset: 10, onDismiss: {
          // A modal just closes, keeping its story so it can slide away whole.
          if isModal {
            presenter.dismiss()
          } else {
            presenter.story = nil
          }
        })
          .accessibilityHidden(presenter.mode == .comments)
      }
      if presenter.mode == .comments {
        CommentsView(story: story, onOpenArticle: { presenter.mode = .article })
          .transition(.opacity)
      }
    }
    .background(Color("cardBg"))
    // Concentric so the corners beside the display's own corners follow
    // its curve, while the inner corners match the story cards.
    .clipShape(ConcentricRectangle(corners: .concentric(minimum: .fixed(16))))
    .padding(.leading, 12)
    .padding(.trailing, hingeEdge == .trailing ? 4 : 12)
    .padding(.bottom, hingeEdge == .bottom ? 4 : 12)
    .ignoresSafeArea(.container, edges: .bottom)
  }

  private func header(_ story: Story) -> some View {
    HStack(spacing: 8) {
      if !story.url.isEmpty {
        HStack(spacing: 0) {
          modeButton("Article", systemImage: "safari", mode: .article)
          modeButton("Comments", systemImage: "text.bubble", mode: .comments)
        }
        .glassEffect(in: .capsule)
      }
      // The status items sit at the trailing end of the row.
      Spacer()
    }
    .buttonStyle(.plain)
    .foregroundStyle(Color("titleColor"))
    // Mirrors the status items' inset from the trailing edge.
    .padding(.leading, 28)
    .padding(.trailing, 12)
  }

  private func modeButton(_ title: String, systemImage: String, mode: StoryPresenter.Mode) -> some View {
    let isSelected = presenter.mode == mode
    return Button(action: { presenter.mode = mode }) {
      Image(systemName: systemImage)
        .symbolVariant(isSelected ? .fill : .none)
        .font(.system(size: 18, weight: .semibold))
        .frame(width: 48, height: 44)
    }
    .accessibilityLabel(title)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}
#endif
