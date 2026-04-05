//
//  StoryView.swift
//  Hackery
//
//  Created by Tim Shim on 31/5/20.
//  Copyright © 2020 Tim Shim. All rights reserved.
//

import SwiftUI

struct StoryView: View {
  @Environment(FeedViewModel.self) private var viewModel
  @Environment(BookmarkStore.self) private var bookmarkStore
  @Environment(EngagementTracker.self) private var engagement

  var story: Story
  var onShowComments: (() -> Void)?

  #if os(iOS)
  @State private var showComments = false
  #endif

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      #if os(iOS)
      Text(story.title)
        .multilineTextAlignment(.leading)
        .font(.custom("Lato-Bold", size: 18, relativeTo: .headline))
        .foregroundColor(Color("titleColor"))
        .padding(EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: bookmarkStore.isBookmarked(story) ? 36 : 16))
      #elseif os(visionOS)
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
      .padding(.bottom, 3)
      #endif
      HStack(alignment: .bottom) {
        VStack(alignment: .leading) {
          Text(story.timeAgo)
            .font(.custom("Lato-Regular", size: 15, relativeTo: .subheadline))
            #if os(iOS)
            .foregroundColor(Color("subtitleColor"))
            #elseif os(visionOS)
            .foregroundStyle(.secondary)
            #endif
            .lineLimit(1)
          Text("\(story.score) points")
            .font(.custom("Lato-Regular", size: 15, relativeTo: .subheadline))
            #if os(iOS)
            .foregroundColor(Color("subtitleColor"))
            #elseif os(visionOS)
            .foregroundStyle(.secondary)
            #endif
            .lineLimit(1)
          Text("By \(story.by)")
            .font(.custom("Lato-Regular", size: 15, relativeTo: .subheadline))
            #if os(iOS)
            .foregroundColor(Color("subtitleColor"))
            #elseif os(visionOS)
            .foregroundStyle(.secondary)
            #endif
            .lineLimit(1)
        }
        Spacer()
        if story.descendants > 0 {
          #if os(iOS)
          Button(action: {
            if let onShowComments {
              onShowComments()
            } else {
              showComments = true
            }
          }) {
            CommentButton(count: story.descendants)
          }
          .buttonStyle(BorderlessButtonStyle())
          .sheet(isPresented: $showComments, onDismiss: {
            engagement.checkForPrompt()
          }) {
            CommentsView(story: story)
          }
          #elseif os(visionOS)
          Button(action: { onShowComments?() }) {
            CommentButton(count: story.descendants)
          }
          .buttonStyle(.plain)
          .hoverEffect()
          #endif
        }
      }
      #if os(iOS)
      .padding(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
      #elseif os(visionOS)
      .padding(.top, 3)
      #endif
    }
    #if os(iOS)
    .overlay(alignment: .topTrailing) {
      if bookmarkStore.isBookmarked(story) {
        Image(systemName: "bookmark.fill")
          .font(.system(size: 14))
          .foregroundColor(Color("subtitleColor").opacity(0.5))
          .padding(.top, 20)
          .padding(.trailing, 20)
      }
    }
    #elseif os(visionOS)
    .padding(16)
    #endif
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(story.title), \(story.score) points by \(story.by), \(story.timeAgo)")
  }
}
