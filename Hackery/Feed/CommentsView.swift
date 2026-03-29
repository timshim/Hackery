//
//  CommentsView.swift
//  Hackery
//
//  Created by Tim Shim on 6/17/19.
//  Copyright © 2019 Tim Shim. All rights reserved.
//

import SwiftUI

struct CommentsView: View {
  @Environment(FeedViewModel.self) private var viewModel

  var story: Story

  var body: some View {
    ZStack {
      Color("cardBg")
        .ignoresSafeArea()
      VStack(alignment: .leading) {
        VStack(alignment: .leading, spacing: 5) {
          Text(story.title)
            .multilineTextAlignment(.leading)
            .font(.custom("Lato-Bold", size: 18))
            .foregroundColor(Color("titleColor"))
            .padding(.bottom, 3)
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
          }
        }
        .padding(EdgeInsets(top: 30, leading: 30, bottom: -50, trailing: 30))
        ScrollView {
          LazyVStack {
            ForEach(viewModel.comments) { comment in
              CommentView(comment: comment)
            }
          }
        }
        .padding(.top, 50)
        .ignoresSafeArea(edges: .top)
      }
      if viewModel.isLoading {
        VStack {
          Spacer()
          ProgressView()
          Spacer()
        }
        .ignoresSafeArea()
      }
    }
    .overlay(alignment: .bottom) {
      if let error = viewModel.error {
        ErrorBannerView(message: error)
      }
    }
    .onAppear {
      Task {
        await viewModel.loadComments(for: story)
      }
    }
  }
}

struct CommentView: View {
  var comment: Comment

  var body: some View {
    ZStack {
      Color("cardBg")
        .ignoresSafeArea()
      VStack(alignment: .leading) {
        Text(comment.text)
          .multilineTextAlignment(.leading)
          .font(.custom("Lato-Regular", size: 16))
          .foregroundColor(Color("titleColor"))
          .padding(EdgeInsets(top: 15, leading: 30, bottom: 15, trailing: 30))
        Text("\(comment.by) \(comment.timeAgo.lowercased())")
          .font(.custom("Lato-Regular", size: 16))
          .foregroundColor(Color("subtitleColor"))
          .padding(EdgeInsets(top: 5, leading: 30, bottom: 12, trailing: 30))
        Rectangle()
          .frame(height: 1)
          .foregroundColor(Color("borderColor"))
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(comment.by) said: \(comment.text), \(comment.timeAgo)")
  }
}
