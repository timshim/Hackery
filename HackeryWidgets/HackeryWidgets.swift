//
//  HackeryWidgets.swift
//  HackeryWidgets
//
//  Top Story + Top Stories widgets reading from App Group snapshots.
//

import WidgetKit
import SwiftUI

// MARK: - Shared Timeline Entry

struct StoryEntry: TimelineEntry {
  let date: Date
  let stories: [Story]

  static var placeholder: StoryEntry {
    StoryEntry(date: .now, stories: [
      Story(
        id: 0, by: "dang", descendants: 128, kids: [], score: 342,
        time: Int(Date().timeIntervalSince1970) - 3600,
        title: "Show HN: A new approach to building native apps",
        type: "story", url: "https://example.com", text: nil
      )
    ])
  }
}

// MARK: - Provider

struct TopStoriesProvider: TimelineProvider {
  private static let baseURL = "https://hacker-news.firebaseio.com/v0"
  private static let storyCount = 10

  func placeholder(in context: Context) -> StoryEntry { .placeholder }

  func getSnapshot(in context: Context, completion: @escaping (StoryEntry) -> Void) {
    let stories = SharedSnapshots.readTopStories()
    completion(StoryEntry(date: .now, stories: stories.isEmpty ? StoryEntry.placeholder.stories : stories))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<StoryEntry>) -> Void) {
    let nextUpdate = Calendar.current.date(byAdding: .minute, value: 20, to: .now)!

    Task {
      let stories = await fetchTopStories()
      let resolved = stories.isEmpty ? SharedSnapshots.readTopStories() : stories

      if !stories.isEmpty {
        SharedSnapshots.writeTopStories(stories)
      }

      let entry = StoryEntry(
        date: .now,
        stories: resolved.isEmpty ? StoryEntry.placeholder.stories : resolved
      )
      completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
  }

  private func fetchTopStories() async -> [Story] {
    guard let url = URL(string: "\(Self.baseURL)/topstories.json") else { return [] }
    do {
      let (data, _) = try await URLSession.shared.data(from: url)
      let ids = try JSONDecoder().decode([Int].self, from: data)
      let topIds = Array(ids.prefix(Self.storyCount))

      return await withTaskGroup(of: (Int, Story?).self) { group in
        for (index, id) in topIds.enumerated() {
          group.addTask {
            guard let itemURL = URL(string: "\(Self.baseURL)/item/\(id).json") else {
              return (index, nil)
            }
            do {
              let (itemData, _) = try await URLSession.shared.data(from: itemURL)
              let item = try JSONDecoder().decode(HNItem.self, from: itemData)
              guard item.deleted != true, item.dead != true else { return (index, nil) }
              return (index, Story(from: item))
            } catch {
              return (index, nil)
            }
          }
        }

        var results = [(Int, Story?)]()
        for await result in group {
          results.append(result)
        }
        return results
          .sorted { $0.0 < $1.0 }
          .compactMap { $0.1 }
      }
    } catch {
      return []
    }
  }
}

// MARK: - Top Story Widget (single headline)

struct TopStoryWidget: Widget {
  let kind = "TopStory"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: TopStoriesProvider()) { entry in
      TopStoryView(entry: entry)
        .containerBackground(for: .widget) {
          #if os(visionOS)
          Color.clear
          #else
          Rectangle().fill(.fill.tertiary)
          #endif
        }
    }
    .configurationDisplayName("Top Story")
    .description("The current #1 story on Hacker News.")
    #if os(iOS)
    .supportedFamilies([.systemSmall, .accessoryRectangular])
    #else
    .supportedFamilies([.systemSmall])
    #endif
  }
}

struct TopStoryView: View {
  let entry: StoryEntry

  var body: some View {
    if let story = entry.stories.first {
      Link(destination: URL(string: "hackery://story/\(story.id)")!) {
        VStack(alignment: .leading, spacing: 4) {
          Text(story.title)
            .font(.custom("Lato-Bold", size: 15, relativeTo: .subheadline))
            .minimumScaleFactor(0.8)

          Spacer(minLength: 0)

          HStack(spacing: 6) {
            Label("\(story.score)", systemImage: "arrow.up")
            Label("\(story.descendants)", systemImage: "bubble.right")
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
      Text("No stories yet")
        .font(.custom("Lato-Regular", size: 12, relativeTo: .caption))
        .foregroundStyle(.secondary)
    }
  }
}

// MARK: - Top Stories Widget (multiple headlines)

struct TopStoriesWidget: Widget {
  let kind = "TopStories"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: TopStoriesProvider()) { entry in
      TopStoriesListView(entry: entry)
        .padding(.vertical, 2)
        .containerBackground(for: .widget) {
          #if os(visionOS)
          Color.clear
          #else
          Rectangle().fill(.fill.tertiary)
          #endif
        }
    }
    .configurationDisplayName("Top Stories")
    .description("The top stories on Hacker News.")
    .supportedFamilies([.systemMedium, .systemLarge])
  }
}

struct TopStoriesListView: View {
  @Environment(\.widgetFamily) var family
  let entry: StoryEntry

  private var maxCount: Int { family == .systemLarge ? 8 : 3 }
  private var minCount: Int { family == .systemLarge ? 5 : 2 }

  // Rough character budget for a single-line title in the medium widget at
  // font size 12. If the first 4 titles all fit under this, we can pack 4
  // items into the medium widget instead of the usual 3.
  private static let mediumTitleCharBudget = 45

  private var mediumShowsFour: Bool {
    #if os(visionOS)
    return false
    #else
    guard family == .systemMedium, entry.stories.count >= 4 else { return false }
    return entry.stories.prefix(4).allSatisfy { $0.title.count <= Self.mediumTitleCharBudget }
    #endif
  }

  var body: some View {
    if entry.stories.isEmpty {
      Text("Open Hackery to load stories")
        .font(.custom("Lato-Regular", size: 12, relativeTo: .caption))
        .foregroundStyle(.secondary)
    } else if mediumShowsFour {
      storyList(count: 4)
    } else {
      // Try decreasing counts until the content fits without clipping.
      ViewThatFits(in: .vertical) {
        ForEach(Array(stride(from: maxCount, through: minCount, by: -1)), id: \.self) { count in
          storyList(count: count)
        }
      }
    }
  }

  private func storyList(count: Int) -> some View {
    let stories = Array(entry.stories.prefix(count))
    return VStack(alignment: .leading, spacing: 0) {
      ForEach(Array(stories.enumerated()), id: \.element.id) { index, story in
        if index > 0 {
          Divider().padding(.vertical, 4)
        }
        Link(destination: URL(string: "hackery://story/\(story.id)")!) {
          HStack(alignment: .top, spacing: 8) {
            Text("\(index + 1)")
              .font(.custom("Lato-Bold", size: 12, relativeTo: .caption))
              .foregroundStyle(.secondary)
              .frame(width: 16, alignment: .trailing)

            VStack(alignment: .leading, spacing: 2) {
              Text(story.title)
                .font(.custom("Lato-Bold", size: 12, relativeTo: .caption))
                .fixedSize(horizontal: false, vertical: true)

              HStack(spacing: 6) {
                Label("\(story.score)", systemImage: "arrow.up")
                Label("\(story.descendants)", systemImage: "bubble.right")
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
      }
    }
  }
}

// MARK: - Previews

#Preview("Top Story", as: .systemSmall) {
  TopStoryWidget()
} timeline: {
  StoryEntry.placeholder
}

#Preview("Top Stories", as: .systemMedium) {
  TopStoriesWidget()
} timeline: {
  StoryEntry.placeholder
}
