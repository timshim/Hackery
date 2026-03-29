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
  @Environment(BookmarkStore.self) private var bookmarkStore
  @State private var showGlow = false
  @State private var showSafari = false

  var story: Story

  var body: some View {
    NavigationStack {
      ZStack {
        Color("cardBg")
          .ignoresSafeArea()
        VStack(alignment: .leading) {
          VStack(alignment: .leading, spacing: 5) {
          HStack(alignment: .top) {
            Text(story.title)
              .multilineTextAlignment(.leading)
              .font(.custom("Lato-Bold", size: 18, relativeTo: .headline))
              .foregroundColor(Color("titleColor"))
            Spacer()
            Button(action: {
              bookmarkStore.toggle(story)
            }) {
              Image(systemName: bookmarkStore.isBookmarked(story) ? "bookmark.fill" : "bookmark")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color("subtitleColor").opacity(0.8))
                .frame(width: 40, height: 40)
                .overlay(Circle().stroke(Color("borderColor"), lineWidth: 1))
            }
          }
          .padding(.bottom, 3)
          HStack(alignment: .bottom) {
            VStack(alignment: .leading) {
              Text(story.timeAgo)
                .font(.custom("Lato-Regular", size: 15, relativeTo: .subheadline))
                .foregroundColor(Color("subtitleColor"))
                .lineLimit(1)
              Text("\(story.score) points")
                .font(.custom("Lato-Regular", size: 15, relativeTo: .subheadline))
                .foregroundColor(Color("subtitleColor"))
                .lineLimit(1)
              Text("By \(story.by)")
                .font(.custom("Lato-Regular", size: 15, relativeTo: .subheadline))
                .foregroundColor(Color("subtitleColor"))
                .lineLimit(1)
            }
          }
        }
        .padding(EdgeInsets(top: 30, leading: 30, bottom: -50, trailing: 30))
        .contentShape(Rectangle())
        .onTapGesture {
          if let _ = URL(string: story.url), !story.url.isEmpty {
            showSafari = true
          }
        }
        .fullScreenCover(isPresented: $showSafari) {
          if let url = URL(string: story.url) {
            PushedSafariView(url: url)
              .ignoresSafeArea()
          }
        }
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
        .padding(.top, 50)
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
      .navigationBarHidden(true)
      .overlay(alignment: .bottom) {
        if let error = viewModel.error {
          ErrorBannerView(message: error)
        }
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
    result.foregroundColor = Color("titleColor")
    for run in result.runs {
      if run.link != nil {
        result[run.range].underlineStyle = .single
      }
    }
    return result
  }

  private var leadingPadding: CGFloat {
    24 + CGFloat(comment.depth) * 16
  }

  var body: some View {
    ZStack {
      Color("cardBg")
        .ignoresSafeArea()
      VStack(spacing: 0) {
        VStack(alignment: .leading) {
          Text(attributedText)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(EdgeInsets(top: 15, leading: leadingPadding, bottom: 15, trailing: 30))
          Text("\(comment.by) \(comment.timeAgo.lowercased())")
            .font(.custom("Lato-Regular", size: 16, relativeTo: .body))
            .foregroundColor(Color("subtitleColor"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(EdgeInsets(top: 5, leading: leadingPadding, bottom: 12, trailing: 30))
        }
        .overlay(alignment: .leading) {
          if comment.depth > 0 {
            Rectangle()
              .fill(Color("borderColor"))
              .frame(width: 2)
              .padding(.leading, leadingPadding - 16)
              .padding(.bottom, 12)
              .padding(.top, 12)
          }
        }
        Rectangle()
          .frame(height: 1)
          .foregroundColor(Color("borderColor"))
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(comment.by) said: \(comment.text), \(comment.timeAgo)")
  }
}
