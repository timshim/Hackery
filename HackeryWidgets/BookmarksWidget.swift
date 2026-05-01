//
//  BookmarksWidget.swift
//  HackeryWidgets
//
//  Shows recent bookmarks from the App Group snapshot.
//  Static timeline — refreshed by the main app via WidgetCenter.
//

import WidgetKit
import SwiftUI

// MARK: - Provider

struct BookmarksProvider: TimelineProvider {
  func placeholder(in context: Context) -> StoryEntry { .placeholder }

  func getSnapshot(in context: Context, completion: @escaping (StoryEntry) -> Void) {
    let bookmarks = SharedSnapshots.readBookmarks()
    completion(StoryEntry(date: .now, stories: bookmarks.isEmpty ? StoryEntry.placeholder.stories : bookmarks))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<StoryEntry>) -> Void) {
    let bookmarks = SharedSnapshots.readBookmarks()
    let entry = StoryEntry(date: .now, stories: bookmarks.isEmpty ? StoryEntry.placeholder.stories : bookmarks)
    // No automatic refresh — the main app triggers reloadTimelines on bookmark change.
    completion(Timeline(entries: [entry], policy: .never))
  }
}

// MARK: - Widget

struct BookmarksWidget: Widget {
  let kind = "Bookmarks"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: BookmarksProvider()) { entry in
      BookmarksWidgetView(entry: entry)
        .containerBackground(for: .widget) {
          #if os(visionOS)
          Color.clear
          #else
          Rectangle().fill(.fill.tertiary)
          #endif
        }
    }
    .configurationDisplayName("Bookmarks")
    .description("Your most recent Hacker News bookmarks.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

// MARK: - Views

struct BookmarksWidgetView: View {
  @Environment(\.widgetFamily) var family
  let entry: StoryEntry

  // Rough character budget for a single-line title. If the first N titles
  // all fit under this, we can pack one extra item into the list.
  private static let titleCharBudget = 45

  private var listCount: Int {
    switch family {
    case .systemLarge:
      let base = 5
      if entry.stories.count >= base + 1,
         entry.stories.prefix(base + 1).allSatisfy({ $0.title.count <= Self.titleCharBudget }) {
        return base + 1
      }
      return base
    default:
      let base = 2
      #if os(visionOS)
      return base
      #else
      if entry.stories.count >= base + 1,
         entry.stories.prefix(base + 1).allSatisfy({ $0.title.count <= Self.titleCharBudget }) {
        return base + 1
      }
      return base
      #endif
    }
  }

  var body: some View {
    switch family {
    case .systemSmall:
      smallView
    default:
      listView
    }
  }

  // Single bookmark — small
  private var smallView: some View {
    Group {
      if let story = entry.stories.first {
        Link(destination: URL(string: "hackery://story/\(story.id)")!) {
          VStack(alignment: .leading, spacing: 4) {
            Image(systemName: "bookmark.fill")
              .font(.caption2)
              .foregroundStyle(.orange)

            HStack {
              Text(story.title)
                .font(.custom("Lato-Bold", size: 15, relativeTo: .subheadline))
                .lineLimit(3)
                .minimumScaleFactor(0.8)
              Spacer()
            }

            Spacer(minLength: 0)

            HStack(spacing: 12) {
              Label("\(story.score)", systemImage: "arrow.up")
                .labelStyle(SpacedLabelStyle(spacing: 4))
              Label("\(story.descendants)", systemImage: "bubble.right")
                .labelStyle(SpacedLabelStyle(spacing: 4))
            }
            .font(.custom("Lato-Regular", size: 11, relativeTo: .caption2))
            .foregroundStyle(.secondary)

            if !story.domain.isEmpty {
              Text(story.domain)
                .font(.custom("Lato-Regular", size: 11, relativeTo: .caption2))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
            }
          }
        }
      } else {
        emptyView
      }
    }
  }

  // Multiple bookmarks — medium / large
  private var listView: some View {
    let bookmarks = Array(entry.stories.prefix(listCount))

    return VStack(alignment: .leading, spacing: 0) {
      HStack {
        Image(systemName: "bookmark.fill")
          .font(.caption2)
          .foregroundStyle(.orange)
        Text("Bookmarks")
          .font(.custom("Lato-Bold", size: 12, relativeTo: .caption))
          .foregroundStyle(.secondary)
      }
      .padding(.bottom, 8)

      if bookmarks.isEmpty {
        emptyView
      } else {
        VStack {
          Spacer()
          ForEach(Array(bookmarks.enumerated()), id: \.element.id) { index, story in
            if index > 0 {
              Divider().padding(.vertical, 4)
            }
            Link(destination: URL(string: "hackery://story/\(story.id)")!) {
              VStack(alignment: .leading, spacing: 4) {
                HStack {
                  Text(story.title)
                    .font(.custom("Lato-Bold", size: 14, relativeTo: .caption))
                    .fixedSize(horizontal: false, vertical: true)
                  Spacer()
                }

                HStack(spacing: 12) {
                  Label("\(story.score)", systemImage: "arrow.up")
                    .labelStyle(SpacedLabelStyle(spacing: 4))
                  Label("\(story.descendants)", systemImage: "bubble.right")
                    .labelStyle(SpacedLabelStyle(spacing: 4))
                  if !story.domain.isEmpty {
                    Text(story.domain)
                  }
                }
                .font(.custom("Lato-Regular", size: 11, relativeTo: .caption2))
                .foregroundStyle(.secondary)
                .lineLimit(1)
              }
            }
          }
          Spacer()
        }
      }

      Spacer(minLength: 0)
    }
  }

  private var emptyView: some View {
    Link(destination: URL(string: "hackery://bookmarks")!) {
      VStack {
        Spacer()
        Text("No bookmarks yet")
          .font(.custom("Lato-Regular", size: 12, relativeTo: .caption))
          .foregroundStyle(.secondary)
        Text("Tap to browse")
          .font(.custom("Lato-Regular", size: 11, relativeTo: .caption2))
          .foregroundStyle(.tertiary)
        Spacer()
      }
      .frame(maxWidth: .infinity)
    }
  }
}

// MARK: - Previews

#Preview("Bookmarks Small", as: .systemSmall) {
  BookmarksWidget()
} timeline: {
  StoryEntry.placeholder
}

#Preview("Bookmarks Medium", as: .systemMedium) {
  BookmarksWidget()
} timeline: {
  StoryEntry.placeholder
}
