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
  @Environment(BookmarkStore.self) private var bookmarkStore
  @Environment(\.dismiss) private var dismiss
  @State private var showGlow = false

  var story: Story

  var body: some View {
    ZStack {
      Color.clear
        .ignoresSafeArea()
      VStack(alignment: .leading, spacing: 0) {
        HStack {
          Button(action: { dismiss() }) {
            Image(systemName: "xmark")
              .font(.system(size: 14, weight: .semibold))
              .foregroundStyle(.secondary)
              .frame(width: 32, height: 32)
              .background(.ultraThinMaterial, in: Circle())
          }
          .buttonStyle(.plain)
          Spacer()
          Button(action: {
            bookmarkStore.toggle(story)
          }) {
            Image(systemName: bookmarkStore.isBookmarked(story) ? "bookmark.fill" : "bookmark")
              .font(.system(size: 14, weight: .semibold))
              .foregroundStyle(bookmarkStore.isBookmarked(story) ? .white : .secondary.opacity(0.8))
              .frame(width: 32, height: 32)
              .background(
                bookmarkStore.isBookmarked(story)
                  ? AnyShapeStyle(.cyan.opacity(0.6))
                  : AnyShapeStyle(.ultraThinMaterial),
                in: Circle()
              )
          }
          .buttonStyle(.plain)
          .hoverEffect()
        }
        .padding(EdgeInsets(top: 24, leading: 32, bottom: 20, trailing: 32))

        VStack(alignment: .leading, spacing: 5) {
          Text(story.title)
            .multilineTextAlignment(.leading)
            .font(.custom("Lato-Bold", size: 24, relativeTo: .title))
            .padding(.bottom, 3)
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
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.hoverEffect, .rect(cornerRadius: 12))
        .hoverEffect()
        .contentShape(Rectangle())
        .onTapGesture {
          if let url = URL(string: story.url), !story.url.isEmpty {
            UIApplication.shared.open(url)
          }
        }
        .padding(EdgeInsets(top: 0, leading: 32, bottom: 24, trailing: 32))

        ScrollView {
          LazyVStack(spacing: 0) {
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
        .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
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
    result.font = .custom("Lato-Regular", size: 16, relativeTo: .body)
    for run in result.runs {
      if run.link != nil {
        result[run.range].underlineStyle = .single
        result[run.range].font = .custom("Lato-Bold", size: 16, relativeTo: .body)
        result[run.range].foregroundColor = nil
      }
    }
    return result
  }

  private var leadingPadding: CGFloat {
    32 + CGFloat(comment.depth) * 16
  }

  var body: some View {
    VStack(spacing: 0) {
      VStack(alignment: .leading) {
        Text(attributedText)
          .tint(.primary)
          .multilineTextAlignment(.leading)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(EdgeInsets(top: 18, leading: leadingPadding, bottom: 18, trailing: 32))
        Text("\(comment.by) \(comment.timeAgo.lowercased())")
          .font(.custom("Lato-Regular", size: 14, relativeTo: .body))
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(EdgeInsets(top: 5, leading: leadingPadding, bottom: 16, trailing: 32))
      }
      .overlay(alignment: .leading) {
        if comment.depth > 0 {
          Rectangle()
            .fill(.secondary.opacity(0.3))
            .frame(width: 2)
            .padding(.leading, leadingPadding - 16)
            .padding(.vertical, 12)
        }
      }
      Rectangle()
        .frame(height: 1)
        .foregroundStyle(.secondary.opacity(0.3))
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(comment.by) said: \(comment.text), \(comment.timeAgo)")
  }
}
