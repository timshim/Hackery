//
//  AppDelegate.swift
//  Hackery
//
//  Created by Tim Shim on 6/10/19.
//  Copyright © 2019 Tim Shim. All rights reserved.
//

import SwiftUI
import SwiftData

#if os(iOS)
private struct IsPagingKey: EnvironmentKey {
  static let defaultValue = false
}

extension EnvironmentValues {
  var isPaging: Bool {
    get { self[IsPagingKey.self] }
    set { self[IsPagingKey.self] = newValue }
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
      PageCarousel {
        BookmarksView()
      } trailing: {
        FeedView()
      }
      .background(Color("background"))
      .ignoresSafeArea()
      .environment(viewModel)
      .environment(bookmarkStore)
      .environment(moderationStore)
      .environment(tipStore)
      .environment(engagement)
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
        leading
          .frame(width: width, height: geo.size.height)
        trailing
          .frame(width: width, height: geo.size.height)
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
