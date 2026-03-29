//
//  CommentsView.swift
//  HackeryV
//
//  Created by Tim Shim on 6/8/23.
//  Copyright © 2023 Tim Shim. All rights reserved.
//

import SwiftUI

struct CommentsView: View {
  @Environment(FeedViewModel.self) private var viewModel
  @State private var showGlow = false

  var story: Story

  var body: some View {
    ZStack {
      Color("cardBg")
        .ignoresSafeArea()
      VStack(alignment: .leading) {
        VStack(alignment: .leading, spacing: 5) {
          Text(story.title)
            .multilineTextAlignment(.leading)
            .font(.system(.title, design: .rounded))
            .padding(.bottom, 3)
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
          }
        }
        .padding(.horizontal, 32)
        ScrollView {
          LazyVStack {
            ForEach(viewModel.comments) { comment in
              CommentView(comment: comment)
            }
            if viewModel.hasMoreComments && !viewModel.comments.isEmpty && !viewModel.isLoading {
              Color.clear
                .frame(height: 1)
                .onAppear {
                  Task { await viewModel.loadMoreComments() }
                }
            }
          }
        }
        .ignoresSafeArea(edges: .top)
      }
      VStack {
        Spacer()
        PaginationGlow()
      }
      .ignoresSafeArea()
      .allowsHitTesting(false)
      .opacity(showGlow ? 1 : 0)
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
      viewModel.loadComments(for: story)
    }
    .onChange(of: viewModel.isLoadingMoreComments) { _, loading in
      if loading {
        withAnimation(.easeIn(duration: 0.3)) { showGlow = true }
      } else {
        withAnimation(.easeOut(duration: 0.6)) { showGlow = false }
      }
    }
  }
}

struct CommentView: View {
  var comment: Comment

  private var attributedText: AttributedString {
    var result = (try? AttributedString(
      markdown: comment.text,
      options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
    )) ?? AttributedString(comment.text)
    result.font = .system(.body, design: .rounded)
    for run in result.runs {
      if run.link != nil {
        result[run.range].underlineStyle = .single
      }
    }
    return result
  }

  private var leadingPadding: CGFloat {
    30 + CGFloat(comment.depth) * 16
  }

  var body: some View {
    ZStack {
      VStack(spacing: 0) {
        VStack(alignment: .leading) {
          Text(attributedText)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(EdgeInsets(top: 15, leading: leadingPadding, bottom: 15, trailing: 30))
          Text("\(comment.by) \(comment.timeAgo.lowercased())")
            .font(.system(.body, design: .rounded))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(EdgeInsets(top: 5, leading: leadingPadding, bottom: 12, trailing: 30))
        }
        .overlay(alignment: .leading) {
          if comment.depth > 0 {
            Rectangle()
              .fill(.secondary.opacity(0.3))
              .frame(width: 2)
              .padding(.leading, leadingPadding - 12)
          }
        }
        Rectangle()
          .frame(height: 1)
          .foregroundColor(.secondary)
          .padding(.horizontal, 32)
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(comment.by) said: \(comment.text), \(comment.timeAgo)")
  }
}
