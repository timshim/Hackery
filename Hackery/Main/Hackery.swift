//
//  AppDelegate.swift
//  Hackery
//
//  Created by Tim Shim on 6/10/19.
//  Copyright © 2019 Tim Shim. All rights reserved.
//

import SwiftUI
import SwiftData
import CoreSpotlight

#if os(iOS)
private struct IsPagingKey: EnvironmentKey {
  static let defaultValue = false
}

private struct OpensInReaderKey: EnvironmentKey {
  static let defaultValue = true
}

/// Where a story list sits relative to the detail pane, so its cards can line
/// up with it.
enum StoryListPlacement {
  /// On its own, or with a story open over it.
  case alone
  /// Beside the pane, with a gutter for the selection indicator.
  case besidePane
  /// Below the pane, spanning the width of the pane's card.
  case belowPane

  var leadingCardInset: CGFloat {
    switch self {
    case .alone: 8
    case .besidePane: SelectionIndicator.gutterWidth
    case .belowPane: 12
    }
  }

  var trailingCardInset: CGFloat {
    self == .belowPane ? 12 : 8
  }

  /// Phone-width on their own, but as wide as the pane's card below it.
  var maxWidth: CGFloat {
    self == .belowPane ? .infinity : 500
  }
}

private struct StoryListPlacementKey: EnvironmentKey {
  static let defaultValue = StoryListPlacement.alone
}


extension EnvironmentValues {
  var isPaging: Bool {
    get { self[IsPagingKey.self] }
    set { self[IsPagingKey.self] = newValue }
  }

  var storyListPlacement: StoryListPlacement {
    get { self[StoryListPlacementKey.self] }
    set { self[StoryListPlacementKey.self] = newValue }
  }

  /// Whether Safari views enter Reader mode when it's available.
  var opensInReader: Bool {
    get { self[OpensInReaderKey.self] }
    set { self[OpensInReaderKey.self] = newValue }
  }
}

/// The story shown beside the list when the arrangement has room for a
/// detail pane. Lists read it as an optional environment object: present
/// means taps open in the pane, absent means they present full screen.
@MainActor
@Observable
final class StoryPresenter {
  enum Mode: Hashable {
    case article
    case comments
  }

  var story: Story? {
    didSet { if story == nil { isExpanded = false } }
  }
  var mode: Mode = .article
  /// Whether the story is open over the list, where there's no room for it to
  /// sit beside the list.
  var isExpanded = false
  /// Whether the arrangement has a pane to show a story in, beside or over
  /// the list.
  var hasPane = false

  func show(_ story: Story, mode: Mode) {
    self.story = story
    // Ask/Show HN text posts have no article to load.
    self.mode = story.url.isEmpty ? .comments : mode
    // Rises over the list where there's no room for it beside the list.
    withAnimation(.smooth(duration: 0.35)) { isExpanded = true }
  }

  func dismiss() {
    withAnimation(.easeOut(duration: 0.3)) { isExpanded = false }
  }

  /// Selects a story for an empty pane without opening it over the list.
  func preselect(_ story: Story) {
    self.story = story
    mode = story.url.isEmpty ? .comments : .article
  }
}
#endif

@main
struct Hackery: App {
  @State private var viewModel = FeedViewModel()

  private let modelContainer: ModelContainer
  @State private var bookmarkStore: BookmarkStore
  @State private var moderationStore: ModerationStore
  @State private var blocklistStore: BlocklistStore
  @State private var tipStore = TipStore()
  @State private var engagement = EngagementTracker()
  @State private var router = DeepLinkRouter()
  @State private var deepLinkStory: Story?
  #if os(iOS)
  @State private var presenter = StoryPresenter()
  #endif

  #if os(visionOS)
  @State private var showGlow = false
  @AppStorage("eulaAccepted") private var eulaAccepted = false
  #endif

  init() {
    let schema = Schema([BookmarkedStory.self, ModerationPreference.self, BlockedUser.self, BlockedStory.self])
    let container: ModelContainer
    #if targetEnvironment(simulator)
    let cloudKit: ModelConfiguration.CloudKitDatabase = .none
    #else
    let cloudKit: ModelConfiguration.CloudKitDatabase = .automatic
    #endif
    do {
      let config = ModelConfiguration(
        "Bookmarks",
        schema: schema,
        cloudKitDatabase: cloudKit
      )
      container = try ModelContainer(for: schema, configurations: [config])
    } catch {
      let config = ModelConfiguration(
        "Bookmarks",
        schema: schema,
        cloudKitDatabase: .none
      )
      container = try! ModelContainer(for: schema, configurations: [config])
    }
    self.modelContainer = container
    self._bookmarkStore = State(initialValue: BookmarkStore(modelContext: container.mainContext))
    self._moderationStore = State(initialValue: ModerationStore(modelContext: container.mainContext))
    self._blocklistStore = State(initialValue: BlocklistStore(modelContext: container.mainContext))
  }

  var body: some Scene {
    WindowGroup {
      #if os(iOS)
      StoryArrangement(presenter: presenter) {
        // One container for both pages, so its side bar stays put while
        // they slide beneath it.
        NavigationStack {
          PageCarousel {
            BookmarksView()
          } trailing: {
            FeedView()
          }
          .background(Color("background").ignoresSafeArea())
          .modifier(StoryListBarItems(refresh: { viewModel.loadTopStories(refresh: true) }))
        }
      }
      .environment(viewModel)
      .environment(bookmarkStore)
      .environment(moderationStore)
      .environment(tipStore)
      .environment(engagement)
      .environment(router)
      .onAppear {
        SharedSnapshots.writeBookmarks(bookmarkStore.bookmarks)
        SpotlightIndexer.reindexBookmarks(bookmarkStore.bookmarks)
      }
      .onOpenURL { router.handle(url: $0) }
      .onContinueUserActivity(CSSearchableItemActionType) { activity in
        router.handle(activity: activity)
      }
      .onChange(of: router.pending) { _, destination in
        handleRouterChange(destination)
      }
      .sheet(item: $deepLinkStory) { story in
        CommentsView(story: story)
          .environment(viewModel)
          .environment(bookmarkStore)
          .environment(moderationStore)
          .environment(tipStore)
          .environment(engagement)
      }
      #elseif os(visionOS)
      ZStack {
        FeedView()
          .frame(minWidth: 500, maxWidth: 500)
          .padding()
          .environment(viewModel)
          .environment(bookmarkStore)
          .environment(moderationStore)
          .environment(blocklistStore)
          .environment(tipStore)
      .environment(engagement)
        VStack {
          Spacer()
          PaginationGlow()
        }
        .allowsHitTesting(false)
        .opacity(showGlow ? 1 : 0)
      }
      .onChange(of: viewModel.isLoadingMore) { _, loading in
        if loading {
          withAnimation(.easeIn(duration: 0.3)) { showGlow = true }
        } else {
          withAnimation(.easeOut(duration: 0.6)) { showGlow = false }
        }
      }
      .onAppear {
        SharedSnapshots.writeBookmarks(bookmarkStore.bookmarks)
        SpotlightIndexer.reindexBookmarks(bookmarkStore.bookmarks)
      }
      .onOpenURL { router.handle(url: $0) }
      .onContinueUserActivity(CSSearchableItemActionType) { activity in
        router.handle(activity: activity)
      }
      .onChange(of: router.pending) { _, destination in
        handleRouterChange(destination)
      }
      .sheet(item: $deepLinkStory) { story in
        CommentsView(story: story)
          .environment(viewModel)
          .environment(bookmarkStore)
          .environment(moderationStore)
          .environment(blocklistStore)
          .environment(tipStore)
          .environment(engagement)
      }
      .sheet(isPresented: .constant(!eulaAccepted)) {
        EULAView(accepted: $eulaAccepted)
          .interactiveDismissDisabled()
      }
      #endif
    }
    #if os(visionOS)
    .defaultSize(width: 500, height: 800)
    .windowResizability(.contentSize)
    #endif
  }

  private func handleRouterChange(_ destination: DeepLinkDestination?) {
    guard let destination else { return }
    switch destination {
    case .story(let id):
      Task { await fetchAndPresentStory(id: id) }
    case .bookmarks:
      // iOS: carousel already exposes bookmarks as the leading pane.
      // visionOS: bookmarks are toggled via FeedView's ornament — a deeper
      // hook-up can be added later if needed.
      break
    }
    router.clear()
  }

  private func fetchAndPresentStory(id: Int) async {
    let urlString = "https://hacker-news.firebaseio.com/v0/item/\(id).json"
    guard let url = URL(string: urlString) else { return }
    do {
      let (data, _) = try await URLSession.shared.data(from: url)
      let item = try JSONDecoder().decode(HNItem.self, from: data)
      await MainActor.run {
        let story = Story(from: item)
        #if os(iOS)
        // Opens like a story tapped in the list, wherever there's a pane.
        if presenter.hasPane {
          presenter.show(story, mode: .comments)
          return
        }
        #endif
        deepLinkStory = story
      }
    } catch {
      // Swallow — deep link fetch failures shouldn't crash the app.
    }
  }
}

#if os(iOS)
struct PageCarousel<Leading: View, Trailing: View>: View {
  @ViewBuilder let leading: Leading
  @ViewBuilder let trailing: Trailing

  @State private var showLeading = false
  @State private var isPaging = false
  @GestureState private var dragOffset: CGFloat = 0

  var body: some View {
    GeometryReader { geo in
      let width = geo.size.width
      let baseOffset: CGFloat = showLeading ? 0 : -width
      let clampedDrag = max(min(dragOffset, showLeading ? 0 : width), showLeading ? -width : 0)
      let offset = baseOffset + clampedDrag

      HStack(spacing: 0) {
        // Clipping doesn't stop the off-screen page taking touches, which
        // matters once the carousel is a column beside other content.
        leading
          .frame(width: width, height: geo.size.height)
          .allowsHitTesting(showLeading)
        trailing
          .frame(width: width, height: geo.size.height)
          .allowsHitTesting(!showLeading)
      }
      .environment(\.isPaging, isPaging)
      .offset(x: offset)
      .animation(.easeOut(duration: 0.3), value: showLeading)
      .simultaneousGesture(
        DragGesture(minimumDistance: 30)
          .updating($dragOffset) { value, state, _ in
            let h = value.translation.width
            let v = abs(value.translation.height)
            guard abs(h) > v else { return }
            state = h
          }
          .onChanged { value in
            let h = abs(value.translation.width)
            let v = abs(value.translation.height)
            if h > v && h > 30 {
              isPaging = true
            }
          }
          .onEnded { value in
            let h = value.translation.width
            let v = abs(value.translation.height)
            let velocity = value.predictedEndTranslation.width

            if abs(h) > v {
              if showLeading {
                if h < -60 || velocity < -300 {
                  showLeading = false
                }
              } else {
                if h > 60 || velocity > 300 {
                  showLeading = true
                }
              }
            }

            isPaging = false
          }
      )
    }
    // Sideways only: in a column the off-screen page would otherwise draw
    // over its neighbour, but backgrounds and lists still run under the
    // status bar and home indicator.
    .mask(Rectangle().padding(.vertical, -1000))
  }
}

/// On a device with a fold, the inner display shows the selected story beside
/// the list, with the list on the trailing side so it carries straight over
/// from the outer display. Folded upright, the story takes the top half and
/// the list the bottom; flat and upright, a story opens over the list as a
/// modal.
struct StoryArrangement<Stories: View>: View {
  let presenter: StoryPresenter
  @ViewBuilder let stories: Stories

  var body: some View {
    if #available(iOS 27.1, *) {
      FoldAwareStoryColumns(presenter: presenter, stories: stories)
    } else {
      stories
    }
  }
}

@available(iOS 27.1, *)
private struct FoldAwareStoryColumns<Stories: View>: View {
  @Environment(FeedViewModel.self) private var viewModel
  let presenter: StoryPresenter
  let stories: Stories

  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.horizontalSizeClass) private var sizeClass
  // Sticky, because the outer display has no fold of its own but is still
  // on a foldable, where pages read better than Reader mode.
  @State private var isFoldable = false
  // The fold isn't reported until the scene first becomes active, so until
  // then a foldable's inner display looks just like an iPad.
  @State private var isSettled = false

  var body: some View {
    GeometryReader { proxy in
      let columns = StoryColumns(proxy: proxy, isExpanded: presenter.isExpanded)
      // Both views stay in the same place in the hierarchy whatever the
      // arrangement, so the list keeps its scroll position as the device
      // opens, folds and rotates.
      StoryColumnsLayout(paneFrame: columns.paneFrame, listFrame: columns.listFrame) {
        stories
          .environment(columns.mode == .listOnly ? nil : presenter)
          .environment(\.storyListPlacement, columns.mode.listPlacement)
          // Held back until then where it would show the iPad grid, rather
          // than flash it before the columns.
          .opacity(isSettled || sizeClass == .compact ? 1 : 0)
        StoryDetailPane(
          isModal: columns.mode == .stacked,
          showsModeSwitch: columns.mode == .stacked || columns.mode == .topAndBottom,
          // Read here rather than in the pane, whose own inset shrinks as it
          // slides away from the status bar.
          statusBarInset: proxy.safeAreaInsets.top,
          hingeEdge: columns.paneHingeEdge)
          .environment(presenter)
          // Rises from below as a modal, and drops back when dismissed.
          .offset(y: columns.modalOffset)
          // Off the edge of the safe area isn't always off screen, as with
          // the outer display's side bar, so a hidden pane is also clear.
          .opacity(columns.paneFrame == nil ? 0 : 1)
          .allowsHitTesting(columns.isPaneVisible)
          .accessibilityHidden(!columns.isPaneVisible)
      }
      .onChange(of: columns.mode, initial: true) { _, mode in
        presenter.hasPane = mode != .listOnly
        if mode != .listOnly {
          isFoldable = true
          isSettled = true
        }
        if mode.isSplit { showTopStoryIfNeeded() }
      }
      // On a cold start the stories can arrive after the split appears.
      .onChange(of: viewModel.stories.first?.id) { oldID, _ in
        if oldID == nil && columns.mode.isSplit { showTopStoryIfNeeded() }
      }
    }
    // Shows through the gap left over the fold.
    .background(Color("background").ignoresSafeArea())
    .environment(\.opensInReader, !isFoldable)
    // Any fold turns up a moment after the scene first becomes active.
    .onChange(of: scenePhase, initial: true) { _, phase in
      if phase == .active {
        Task { isSettled = true }
      }
    }
    .onHingeChange { _, context in
      if context.hinge != nil { isFoldable = true }
    }
  }

  private func showTopStoryIfNeeded() {
    guard presenter.story == nil, let story = viewModel.stories.first else { return }
    presenter.preselect(story)
  }
}

/// Where the detail pane and the story list go for the space available.
@available(iOS 27.1, *)
private struct StoryColumns {
  enum Mode: Equatable {
    /// No fold: a phone, an iPad, or a foldable's outer display.
    case listOnly
    /// Wide: the story beside the list.
    case sideBySide
    /// Folded upright: the story above the fold, the list below.
    case topAndBottom
    /// Flat and upright: the story over the list, as a modal, when open.
    case stacked

    var isSplit: Bool { self == .sideBySide || self == .topAndBottom }

    var listPlacement: StoryListPlacement {
      switch self {
      case .listOnly, .stacked: .alone
      case .sideBySide: .besidePane
      case .topAndBottom: .belowPane
      }
    }
  }

  let mode: Mode
  // The list's share of the width when the device is flat.
  private static let flatListRatio: CGFloat = 0.4

  /// Nil when the pane is parked out of the way.
  let paneFrame: CGRect?
  /// The edge of the pane's card that meets the hinge while folded.
  let paneHingeEdge: Edge?
  let listFrame: CGRect
  /// How far below its frame the modal pane waits while it's closed.
  let modalOffset: CGFloat

  var isPaneVisible: Bool { paneFrame != nil && modalOffset == 0 }

  init(proxy: GeometryProxy, isExpanded: Bool) {
    let size = proxy.size
    let bounds = CGRect(origin: .zero, size: size)
    // Include inactive regions so the arrangement follows the hardware rather
    // than the hinge angle, and only the split point moves as it folds.
    let folds = proxy.reservedRegions(kind: .division, options: .includeInactive)
    let fold = folds.first(where: \.isActive)

    if folds.isEmpty {
      mode = .listOnly
      paneFrame = nil
      paneHingeEdge = nil
      listFrame = bounds
    } else if size.width > size.height {
      mode = .sideBySide
      if let fold {
        // Folded like a book, each takes exactly its side of the hinge.
        let hinge = Self.hinge(of: fold)
        paneFrame = CGRect(x: 0, y: 0, width: hinge.minX, height: size.height)
        paneHingeEdge = .trailing
        listFrame = CGRect(x: hinge.maxX, y: 0, width: size.width - hinge.maxX, height: size.height)
      } else {
        let split = size.width * (1 - Self.flatListRatio)
        paneFrame = CGRect(x: 0, y: 0, width: split, height: size.height)
        paneHingeEdge = nil
        listFrame = CGRect(x: split, y: 0, width: size.width - split, height: size.height)
      }
    } else if let fold {
      // The top reads at a distance; the bottom is easier to reach.
      mode = .topAndBottom
      let hinge = Self.hinge(of: fold)
      paneFrame = CGRect(x: 0, y: 0, width: size.width, height: hinge.minY)
      paneHingeEdge = .bottom
      listFrame = CGRect(x: 0, y: hinge.maxY, width: size.width, height: size.height - hinge.maxY)
    } else {
      mode = .stacked
      paneFrame = bounds
      paneHingeEdge = nil
      listFrame = bounds
    }
    // Past the bottom safe area too, so no edge of it shows while closed.
    modalOffset = mode == .stacked && !isExpanded ? size.height * 1.2 : 0
  }

  /// The hinge itself, without the margins the system leaves around it for
  /// interactive content. Both sides scroll, which is fine that close to the
  /// curve, and lets them meet right at it.
  private static func hinge(of region: ReservedRegion) -> CGRect {
    let frame = region.frame
    let margins = region.margins
    return CGRect(
      x: frame.minX + margins.leading,
      y: frame.minY + margins.top,
      width: max(0, frame.width - margins.leading - margins.trailing),
      height: max(0, frame.height - margins.top - margins.bottom))
  }
}

/// Places the story list, then the detail pane over it, at the given frames.
/// A pane with no frame is parked below the bottom edge.
private struct StoryColumnsLayout: Layout {
  var paneFrame: CGRect?
  var listFrame: CGRect

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    proposal.replacingUnspecifiedDimensions()
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    let pane = paneFrame ?? CGRect(x: 0, y: bounds.height, width: bounds.width, height: bounds.height)
    for (subview, frame) in zip(subviews, [listFrame, pane]) {
      subview.place(
        at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
        proposal: ProposedViewSize(frame.size))
    }
  }
}
#endif

#if os(visionOS)
struct EULAView: View {
  @Binding var accepted: Bool

  var body: some View {
    VStack(spacing: 24) {
      Text("End User License Agreement")
        .font(.system(.title, design: .rounded, weight: .bold))
        .multilineTextAlignment(.center)

      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          Text("Welcome to Hackery")
            .font(.headline)
          Text("By using this app, you agree to the following terms:")

          Text("1. Content")
            .font(.headline)
          Text("Hackery displays content from the Hacker News public API. Story content, comments, and links are owned by their respective authors. Hackery is not affiliated with Hacker News or Y Combinator.")

          Text("2. User Conduct")
            .font(.headline)
          Text("You agree not to use this app for any unlawful purpose. You are responsible for any content you choose to view, bookmark, or share through the app.")

          Text("3. Moderation")
            .font(.headline)
          Text("Hackery provides tools to hide, block, and report content. Use of these tools is at your own discretion. Hackery does not guarantee the removal of any third-party content.")

          Text("4. Privacy")
            .font(.headline)
          Text("Bookmarks and blocked items are stored locally and synced across your devices via iCloud (CloudKit). No personal data is transmitted to Hackery's servers.")

          Text("5. Disclaimer")
            .font(.headline)
          Text("This app is provided \"as is\" without warranty of any kind. The developer is not liable for any damages arising from the use of this app.")

          Text("6. Acceptance")
            .font(.headline)
          Text("By tapping \"I Agree\" below, you confirm that you have read, understood, and agree to be bound by these terms.")
        }
        .font(.system(.body, design: .rounded))
        .padding(.horizontal, 4)
      }
      .frame(maxHeight: 360)

      Button(action: { accepted = true }) {
        Text("I Agree")
          .font(.system(.title3, design: .rounded, weight: .semibold))
          .frame(maxWidth: .infinity)
          .padding(.vertical, 8)
      }
      .buttonStyle(.borderedProminent)
    }
    .padding(32)
    .frame(width: 560)
  }
}
#endif
