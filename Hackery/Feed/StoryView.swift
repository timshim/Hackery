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
  @State private var showComments = false

  var story: Story

  var body: some View {
    ZStack {
      Color("cardBg")
      VStack(alignment: .leading, spacing: 5) {
        Text(story.title)
          .multilineTextAlignment(.leading)
          .font(.custom("Lato-Bold", size: 18))
          .foregroundColor(Color("titleColor"))
          .padding(EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16))
        HStack(alignment: .bottom) {
          VStack(alignment: .leading) {
            Text(story.timeAgo)
              .font(.custom("Lato-Regular", size: 15))
              .foregroundColor(Color("subtitleColor"))
              .lineLimit(1)
            Text("\(story.score) points")
              .font(.custom("Lato-Regular", size: 15))
              .foregroundColor(Color("subtitleColor"))
              .lineLimit(1)
            Text("By \(story.by)")
              .font(.custom("Lato-Regular", size: 15))
              .foregroundColor(Color("subtitleColor"))
              .lineLimit(1)
          }
          Spacer()
          if story.descendants > 0 {
            Button(action: {
              showComments = true
            }) {
              CommentButton(count: story.descendants)
            }
            .buttonStyle(BorderlessButtonStyle())
            .sheet(isPresented: $showComments) {
              CommentsView(story: story)
            }
          }
        }
        .padding(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(story.title), \(story.score) points by \(story.by), \(story.timeAgo)")
  }
}
