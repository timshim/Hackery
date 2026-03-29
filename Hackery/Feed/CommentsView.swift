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

  #if os(iOS)
  @State private var showSafari = false
  #elseif os(visionOS)
  @Environment(\.dismiss) private var dismiss
  #endif

  var story: Story

  var body: some View {
    #if os(iOS)
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
          commentsScrollView
        }
        glowOverlay
        loadingOverlay
      }
      .navigationBarHidden(true)
      .overlay(alignment: .bottom) {
        if let error = viewModel.error {
          ErrorBannerView(message: error)
        }
      }
    }
    .onAppear { viewModel.loadComments(for: story) }
    .onChange(of: viewModel.isLoadingMoreComments) { _, loading in
      if loading {
        withAnimation(.easeIn(duration: 0.3)) { showGlow = true }
      } else {
        withAnimation(.easeOut(duration: 0.6)) { showGlow = false }
      }
    }

    #elseif os(visionOS)
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

        commentsScrollView
      }
      glowOverlay
      loadingOverlay
    }
    .overlay(alignment: .bottom) {
      if let error = viewModel.error {
        ErrorBannerView(message: error)
      }
    }
    .onAppear { viewModel.loadComments(for: story) }
    .onChange(of: viewModel.isLoadingMoreComments) { _, loading in
      if loading {
        withAnimation(.easeIn(duration: 0.3)) { showGlow = true }
      } else {
        withAnimation(.easeOut(duration: 0.6)) { showGlow = false }
      }
    }
    #endif
  }

  // MARK: - Shared subviews

  private var commentsScrollView: some View {
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
    #if os(iOS)
    .padding(.top, 50)
    .ignoresSafeArea(edges: .top)
    #endif
  }

  private var glowOverlay: some View {
    VStack {
      Spacer()
      PaginationGlow()
    }
    .ignoresSafeArea()
    .allowsHitTesting(false)
    .opacity(showGlow ? 1 : 0)
  }

  private var loadingOverlay: some View {
    Group {
      if viewModel.isLoading {
        VStack {
          Spacer()
          ProgressView()
          Spacer()
        }
        .ignoresSafeArea()
      }
    }
  }
}

// MARK: - Comment View

struct CommentView: View {
  var comment: Comment

  private var attributedText: AttributedString {
    var result = (try? AttributedString(
      markdown: comment.text,
      options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
    )) ?? AttributedString(comment.text)
    result.font = .custom("Lato-Regular", size: 16, relativeTo: .body)
    #if os(iOS)
    result.foregroundColor = Color("titleColor")
    #endif
    for run in result.runs {
      if run.link != nil {
        result[run.range].underlineStyle = .single
        #if os(visionOS)
        result[run.range].font = .custom("Lato-Bold", size: 16, relativeTo: .body)
        result[run.range].foregroundColor = nil
        #endif
      }
    }
    return result
  }

  private var leadingPadding: CGFloat {
    #if os(iOS)
    24 + CGFloat(comment.depth) * 16
    #elseif os(visionOS)
    32 + CGFloat(comment.depth) * 16
    #endif
  }

  var body: some View {
    #if os(iOS)
    ZStack {
      Color("cardBg")
        .ignoresSafeArea()
      commentContent
    }
    #elseif os(visionOS)
    commentContent
      #if os(visionOS)
      .tint(.primary)
      #endif
    #endif
  }

  private var commentContent: some View {
    VStack(spacing: 0) {
      VStack(alignment: .leading) {
        Text(attributedText)
          .multilineTextAlignment(.leading)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(EdgeInsets(top: 15, leading: leadingPadding, bottom: 15, trailing: 30))
        Text("\(comment.by) \(comment.timeAgo.lowercased())")
          .font(.custom("Lato-Regular", size: 16, relativeTo: .body))
          #if os(iOS)
          .foregroundColor(Color("subtitleColor"))
          #elseif os(visionOS)
          .foregroundStyle(.secondary)
          #endif
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(EdgeInsets(top: 5, leading: leadingPadding, bottom: 12, trailing: 30))
      }
      .overlay(alignment: .leading) {
        if comment.depth > 0 {
          Rectangle()
            #if os(iOS)
            .fill(Color("borderColor"))
            #elseif os(visionOS)
            .fill(.secondary.opacity(0.3))
            #endif
            .frame(width: 2)
            .padding(.leading, leadingPadding - 16)
            .padding(.vertical, 12)
        }
      }
      Rectangle()
        .frame(height: 1)
        #if os(iOS)
        .foregroundColor(Color("borderColor"))
        #elseif os(visionOS)
        .foregroundStyle(.secondary.opacity(0.3))
        #endif
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(comment.by) said: \(comment.text), \(comment.timeAgo)")
  }
}
