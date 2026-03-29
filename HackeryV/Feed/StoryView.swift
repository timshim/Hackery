//
//  StoryView.swift
//  HackeryV
//
//  Created by Tim Shim on 6/8/23.
//  Copyright © 2023 Tim Shim. All rights reserved.
//

import SwiftUI

struct StoryView: View {
  @Environment(FeedViewModel.self) private var viewModel
  @Environment(BookmarkStore.self) private var bookmarkStore

  var story: Story
  var onShowComments: () -> Void = {}

  var body: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .top, spacing: 8) {
        Text(story.title)
          .multilineTextAlignment(.leading)
          .font(.custom("Lato-Bold", size: 20, relativeTo: .title3))
        if bookmarkStore.isBookmarked(story) {
          Spacer()
          Image(systemName: "bookmark.fill")
            .font(.system(size: 14))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(.tint)
            .tint(.cyan)
            .visualEffect { content, _ in
              content.saturation(1.2).brightness(0.1)
            }
            .padding(.top, 3)
        }
      }
      .padding(.bottom, 8)
      HStack(alignment: .bottom) {
        VStack(alignment: .leading) {
          Text(story.timeAgo)
            .font(.custom("Lato-Regular", size: 15, relativeTo: .body))
            .foregroundStyle(.secondary)
            .lineLimit(1)
          Text("\(story.score) points")
            .font(.custom("Lato-Regular", size: 15, relativeTo: .body))
            .foregroundStyle(.secondary)
            .lineLimit(1)
          Text("By \(story.by)")
            .font(.custom("Lato-Regular", size: 15, relativeTo: .body))
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        Spacer()
        if story.descendants > 0 {
          Button(action: onShowComments) {
            CommentButton(count: story.descendants)
          }
          .buttonStyle(.plain)
          .hoverEffect()
        }
      }
    }
    .padding(16)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(story.title), \(story.score) points by \(story.by), \(story.timeAgo)")
  }
}
