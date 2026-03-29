//
//  AppDelegate.swift
//  Hackery
//
//  Created by Tim Shim on 6/10/19.
//  Copyright © 2019 Tim Shim. All rights reserved.
//

import SwiftUI
import SwiftData

private struct IsPagingKey: EnvironmentKey {
  static let defaultValue = false
}

extension EnvironmentValues {
  var isPaging: Bool {
    get { self[IsPagingKey.self] }
    set { self[IsPagingKey.self] = newValue }
  }
}

@main
struct Hackery: App {
  @State private var viewModel = FeedViewModel()

  private let modelContainer: ModelContainer
  @State private var bookmarkStore: BookmarkStore

  init() {
    let schema = Schema([BookmarkedStory.self])
    let container: ModelContainer
    do {
      let config = ModelConfiguration(
        "Bookmarks",
        schema: schema,
        cloudKitDatabase: .automatic
      )
      container = try ModelContainer(for: schema, configurations: [config])
    } catch {
      // Fall back to local-only if CloudKit setup fails
      let config = ModelConfiguration(
        "Bookmarks",
        schema: schema,
        cloudKitDatabase: .none
      )
      container = try! ModelContainer(for: schema, configurations: [config])
    }
    self.modelContainer = container
    self._bookmarkStore = State(initialValue: BookmarkStore(modelContext: container.mainContext))
  }

  var body: some Scene {
    WindowGroup {
      PageCarousel {
        BookmarksView()
      } trailing: {
        FeedView()
      }
      .background(Color("background"))
      .ignoresSafeArea()
      .environment(viewModel)
      .environment(bookmarkStore)
    }
  }
}

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
