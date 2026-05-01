//
//  RefreshIntent.swift
//  HackeryWidgets
//
//  Powers the in-widget refresh button on Top Stories.
//

import AppIntents
import WidgetKit

struct RefreshTopStoriesIntent: AppIntent {
  static var title: LocalizedStringResource = "Refresh Top Stories"
  static var description = IntentDescription("Fetch the latest Hacker News headlines.")

  func perform() async throws -> some IntentResult {
    let stories = await TopStoriesFetcher.fetch()
    if !stories.isEmpty {
      SharedSnapshots.writeTopStories(stories)
    }
    return .result()
  }
}
