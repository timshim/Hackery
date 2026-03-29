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
  @State private var showComments = false

  var story: Story

  var body: some View {
    ZStack {
      VStack(alignment: .leading) {
        Text(story.title)
          .multilineTextAlignment(.leading)
          .font(.system(.title, design: .rounded))
          .padding(.bottom, 16)
        HStack(alignment: .bottom) {
          VStack(alignment: .leading) {
            Text(story.timeAgo)
              .font(.system(.body, design: .rounded))
              .foregroundStyle(.secondary)
              .lineLimit(1)
            Text("\(story.score) points")
              .font(.system(.body, design: .rounded))
              .foregroundStyle(.secondary)
              .lineLimit(1)
            Text("By \(story.by)")
              .font(.system(.body, design: .rounded))
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
          Spacer()
          if story.descendants > 0 {
            Button(action: {
              showComments = true
            }) {
              CommentButton(count: story.descendants)
            }
            .navigationDestination(isPresented: $showComments) {
              CommentsView(story: story)
            }
            .buttonStyle(.plain)
            .hoverEffect()
          }
        }
      }
    }
    .padding(16)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(story.title), \(story.score) points by \(story.by), \(story.timeAgo)")
  }
}
