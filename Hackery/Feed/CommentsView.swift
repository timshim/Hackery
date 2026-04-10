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
  @Environment(ModerationStore.self) private var moderationStore
  @Environment(EngagementTracker.self) private var engagement
  @State private var showGlow = false
  @State private var classifier = CommentClassifier()

  // Alert states
  @State private var blockUserTarget: Comment?
  @State private var showBlockConfirmAlert = false

  // Report states (fallback when AI unavailable)
  @State private var reportTarget: Comment?
  @State private var reportReason = ""
  @State private var showReportSentAlert = false

  // Sensitivity popover
  @State private var showSensitivityPopover = false
  @State private var showEnableAIAlert = false

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
              Button(action: { showSensitivityPopover = true }) {
                Image(systemName: moderationStore.isModerationActive ? "eye.slash" : "eye")
                  .font(.system(size: 14, weight: .medium))
                  .foregroundColor(Color("subtitleColor").opacity(0.8))
                  .frame(width: 40, height: 40)
                  .overlay(Circle().stroke(Color("borderColor"), lineWidth: 1))
              }
              .popover(isPresented: $showSensitivityPopover, arrowEdge: .top) {
                SensitivityPopoverView(moderationStore: moderationStore, classifier: classifier, viewModel: viewModel, classifyComments: classifyComments) {
                  showSensitivityPopover = false
                  showEnableAIAlert = true
                }
              }
              ShareLink(item: URL(string: "hackery://story/\(story.id)")!) {
                Image(systemName: "square.and.arrow.up")
                  .font(.system(size: 14, weight: .medium))
                  .foregroundColor(Color("subtitleColor").opacity(0.8))
                  .frame(width: 40, height: 40)
                  .overlay(Circle().stroke(Color("borderColor"), lineWidth: 1))
              }
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
              engagement.recordInteraction()
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
    .onAppear {
      engagement.recordInteraction()
      // Only reset and load on first appearance for this story
      if viewModel.currentCommentStoryId != story.id {
        moderationStore.resetSession()
        if moderationStore.hideAlways {
          moderationStore.hideOnce = true
        }
      }
      viewModel.loadComments(for: story) { comments in
        guard moderationStore.isModerationActive else { return }
        await classifyCommentsBeforeDisplay(comments)
      }
    }
    .onChange(of: viewModel.isLoadingMoreComments) { _, loading in
      if loading {
        withAnimation(.easeIn(duration: 0.3)) { showGlow = true }
      } else {
        withAnimation(.easeOut(duration: 0.6)) { showGlow = false }
      }
    }
    .onChange(of: viewModel.comments.count) { oldCount, newCount in
      guard moderationStore.isModerationActive, newCount > oldCount,
            !viewModel.isLoading else { return }
      let newComments = Array(viewModel.comments.suffix(newCount - oldCount))
      classifyComments(newComments)
    }
    .modifier(moderationAlerts)

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
          Button(action: { showSensitivityPopover = true }) {
            Image(systemName: moderationStore.isModerationActive ? "eye.slash" : "eye")
              .font(.system(size: 14, weight: .semibold))
              .foregroundStyle(moderationStore.isModerationActive ? .white : .secondary.opacity(0.8))
              .frame(width: 32, height: 32)
              .background(
                moderationStore.isModerationActive
                  ? AnyShapeStyle(.cyan.opacity(0.6))
                  : AnyShapeStyle(.ultraThinMaterial),
                in: Circle()
              )
          }
          .buttonStyle(.plain)
          .hoverEffect()
          .popover(isPresented: $showSensitivityPopover, arrowEdge: .top) {
            SensitivityPopoverView(moderationStore: moderationStore, classifier: classifier, viewModel: viewModel, classifyComments: classifyComments) {
              showSensitivityPopover = false
              showEnableAIAlert = true
            }
          }
          ShareLink(item: URL(string: "hackery://story/\(story.id)")!) {
            Image(systemName: "square.and.arrow.up")
              .font(.system(size: 14, weight: .semibold))
              .foregroundStyle(.secondary.opacity(0.8))
              .frame(width: 32, height: 32)
              .background(.ultraThinMaterial, in: Circle())
          }
          .buttonStyle(.plain)
          .hoverEffect()
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
            engagement.recordInteraction()
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
    .onAppear {
      engagement.recordInteraction()
      // Only reset and load on first appearance for this story
      if viewModel.currentCommentStoryId != story.id {
        moderationStore.resetSession()
        if moderationStore.hideAlways {
          moderationStore.hideOnce = true
        }
      }
      viewModel.loadComments(for: story) { comments in
        guard moderationStore.isModerationActive else { return }
        await classifyCommentsBeforeDisplay(comments)
      }
    }
    .onChange(of: viewModel.isLoadingMoreComments) { _, loading in
      if loading {
        withAnimation(.easeIn(duration: 0.3)) { showGlow = true }
      } else {
        withAnimation(.easeOut(duration: 0.6)) { showGlow = false }
      }
    }
    .onChange(of: viewModel.comments.count) { oldCount, newCount in
      guard moderationStore.isModerationActive, newCount > oldCount,
            !viewModel.isLoading else { return }
      let newComments = Array(viewModel.comments.suffix(newCount - oldCount))
      classifyComments(newComments)
    }
    .modifier(moderationAlerts)
    #endif
  }

  // MARK: - Moderation Helpers

  /// Classifies comments during loading (before they appear). Called from onLoaded callback.
  private func classifyCommentsBeforeDisplay(_ comments: [Comment]) async {
    if moderationStore.sensitivityLevel >= 10 {
      moderationStore.flaggedCommentIds.formUnion(comments.map(\.id))
      return
    }
    if moderationStore.sensitivityLevel >= 9 {
      for comment in comments {
        if CommentClassifier.containsBannedWord(comment.text) {
          moderationStore.flaggedCommentIds.insert(comment.id)
        }
      }
      return
    }
    let flagged = await classifier.classify(comments, sensitivityLevel: moderationStore.sensitivityLevel)
    moderationStore.flaggedCommentIds.formUnion(flagged)
  }

  /// Classifies comments after they're already displayed (for pagination).
  private func classifyComments(_ comments: [Comment]) {
    // Sensitivity 10 = hide all (bypass classifier, for testing)
    if moderationStore.sensitivityLevel >= 10 {
      withAnimation(.easeInOut(duration: 0.3)) {
        moderationStore.flaggedCommentIds.formUnion(comments.map(\.id))
      }
      return
    }
    Task {
      let flagged = await classifier.classify(comments, sensitivityLevel: moderationStore.sensitivityLevel)
      withAnimation(.easeInOut(duration: 0.3)) {
        moderationStore.flaggedCommentIds.formUnion(flagged)
      }
    }
  }

  // MARK: - Moderation Alerts

  private var moderationAlerts: some ViewModifier {
    ModerationAlertModifier(
      showEnableAIAlert: $showEnableAIAlert,
      blockUserTarget: $blockUserTarget,
      showBlockConfirmAlert: $showBlockConfirmAlert,
      reportTarget: $reportTarget,
      reportReason: $reportReason,
      showReportSentAlert: $showReportSentAlert,
      onBlockHide: { username in
        moderationStore.blockUser(username, level: "hide")
      },
      onBlockRemove: { username in
        moderationStore.blockUser(username, level: "remove")
      }
    )
  }

  // MARK: - Shared subviews

  private var commentsScrollView: some View {
    ScrollView {
      LazyVStack(spacing: 0) {
        ForEach(viewModel.comments) { comment in
          ModeratedCommentView(
            comment: comment,
            classifier: classifier,
            onBlockUser: { blockUserTarget = comment },
            onReport: { reportTarget = comment }
          )
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

struct CommentView<Actions: View>: View {
  var comment: Comment
  var actions: Actions

  init(comment: Comment) where Actions == EmptyView {
    self.comment = comment
    self.actions = EmptyView()
  }

  init(comment: Comment, @ViewBuilder actions: () -> Actions) {
    self.comment = comment
    self.actions = actions()
  }

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
      actions
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

// MARK: - Moderated Comment View

struct ModeratedCommentView: View {
  @Environment(ModerationStore.self) private var moderationStore
  var comment: Comment
  var classifier: CommentClassifier
  var onBlockUser: () -> Void
  var onReport: () -> Void

  /// Whether the comment was flagged by AI or belongs to a blocked user,
  /// regardless of whether the user manually unhid it.
  private var isFlaggedOrBlocked: Bool {
    moderationStore.blockedUsers.contains { $0.username == comment.by }
    || (moderationStore.flaggedCommentIds.contains(comment.id) && moderationStore.isModerationActive)
    || (moderationStore.sensitivityLevel >= 10 && moderationStore.isModerationActive)
  }

  @ViewBuilder
  var body: some View {
    if moderationStore.shouldRemoveComment(comment) {
      RemovedCommentView(comment: comment)
    } else {
      commentContent
    }
  }

  @ViewBuilder
  private var commentContent: some View {
    let isClassifying = classifier.classifyingCommentIds.contains(comment.id)
    let shouldHide = moderationStore.shouldHideComment(comment)
    let isUnhidden = moderationStore.manuallyUnhiddenCommentIds.contains(comment.id)

    if isClassifying {
      // Being classified — dimmed/blurred
      CommentView(comment: comment)
        .opacity(0.3)
        .blur(radius: 4)
        .allowsHitTesting(false)
    } else if shouldHide {
      // Hidden
      HiddenCommentView(
        comment: comment,
        canUnhide: moderationStore.canUnhide(comment),
        onUnhide: { moderationStore.unhideComment(comment.id) },
        onBlockUser: onBlockUser
      )
    } else if isFlaggedOrBlocked && isUnhidden {
      // Manually unhidden — show content with action buttons
      CommentView(comment: comment) {
        commentActionButtons
      }
    } else if !classifier.isAvailable && moderationStore.sensitivityLevel < 9 {
      // AI unavailable — show report button
      CommentView(comment: comment) {
        HStack(spacing: 8) {
          Button(action: onReport) {
            HStack(spacing: 4) {
              Image(systemName: "flag")
              Text("Report")
            }
            .font(.custom("Lato-Regular", size: 13, relativeTo: .caption))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            #if os(visionOS)
            .overlay(Capsule().stroke(.secondary.opacity(0.5), lineWidth: 1))
            #else
            .overlay(Capsule().stroke(Color("borderColor"), lineWidth: 1))
            #endif
          }
          .buttonStyle(.plain)
          Spacer()
        }
        .padding(EdgeInsets(top: 4, leading: leadingPadding, bottom: 12, trailing: 30))
        #if os(iOS)
        .foregroundColor(Color("subtitleColor"))
        #elseif os(visionOS)
        .foregroundStyle(.secondary)
        #endif
      }
    } else {
      CommentView(comment: comment)
    }
  }

  private var leadingPadding: CGFloat {
    #if os(iOS)
    24 + CGFloat(comment.depth) * 16
    #elseif os(visionOS)
    32 + CGFloat(comment.depth) * 16
    #endif
  }

  private var commentActionButtons: some View {
    HStack(spacing: 8) {
      Button(action: {
        moderationStore.manuallyUnhiddenCommentIds.remove(comment.id)
      }) {
        HStack(spacing: 4) {
          Image(systemName: "eye.slash")
          Text("Hide")
        }
        .font(.custom("Lato-Regular", size: 13, relativeTo: .caption))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        #if os(visionOS)
        .overlay(Capsule().stroke(.secondary.opacity(0.5), lineWidth: 1))
        #else
        .overlay(Capsule().stroke(Color("borderColor"), lineWidth: 1))
        #endif
      }
      .buttonStyle(.plain)
      Button(role: .destructive, action: onBlockUser) {
        HStack(spacing: 4) {
          Image(systemName: "person.slash")
          Text("Block User")
        }
        .font(.custom("Lato-Regular", size: 13, relativeTo: .caption))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        #if os(visionOS)
        .overlay(Capsule().stroke(.secondary.opacity(0.5), lineWidth: 1))
        #else
        .overlay(Capsule().stroke(Color("borderColor"), lineWidth: 1))
        #endif
      }
      .buttonStyle(.plain)
      Spacer()
    }
    .padding(EdgeInsets(top: 4, leading: leadingPadding, bottom: 12, trailing: 30))
    #if os(iOS)
    .foregroundColor(Color("subtitleColor"))
    #elseif os(visionOS)
    .foregroundStyle(.secondary)
    #endif
  }
}

// MARK: - Hidden Comment View

struct HiddenCommentView: View {
  var comment: Comment
  var canUnhide: Bool
  var onUnhide: () -> Void
  var onBlockUser: () -> Void

  private var leadingPadding: CGFloat {
    #if os(iOS)
    24 + CGFloat(comment.depth) * 16
    #elseif os(visionOS)
    32 + CGFloat(comment.depth) * 16
    #endif
  }

  var body: some View {
    VStack(spacing: 0) {
      VStack(alignment: .leading, spacing: 8) {
        Text("[Hidden]")
          .font(.custom("Lato-Regular", size: 16, relativeTo: .body))
          #if os(iOS)
          .foregroundColor(Color("subtitleColor"))
          #elseif os(visionOS)
          .foregroundStyle(.secondary)
          #endif
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(EdgeInsets(top: 15, leading: leadingPadding, bottom: 0, trailing: 30))
        HStack(spacing: 8) {
          if canUnhide {
            Button(action: onUnhide) {
              HStack(spacing: 4) {
                Image(systemName: "eye")
                Text("Unhide")
              }
              .font(.custom("Lato-Regular", size: 13, relativeTo: .caption))
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              #if os(visionOS)
              .overlay(Capsule().stroke(.secondary.opacity(0.5), lineWidth: 1))
              #else
              .overlay(Capsule().stroke(Color("borderColor"), lineWidth: 1))
              #endif
            }
            .buttonStyle(.plain)
          }
          Button(role: .destructive, action: onBlockUser) {
            HStack(spacing: 4) {
              Image(systemName: "person.slash")
              Text("Block User")
            }
            .font(.custom("Lato-Regular", size: 13, relativeTo: .caption))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            #if os(visionOS)
            .overlay(Capsule().stroke(.secondary.opacity(0.5), lineWidth: 1))
            #else
            .overlay(Capsule().stroke(Color("borderColor"), lineWidth: 1))
            #endif
          }
          .buttonStyle(.plain)
          Spacer()
        }
        .padding(EdgeInsets(top: 4, leading: leadingPadding, bottom: 12, trailing: 30))
        #if os(iOS)
        .foregroundColor(Color("subtitleColor"))
        #elseif os(visionOS)
        .foregroundStyle(.secondary)
        #endif
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
    .accessibilityLabel("Hidden comment by \(comment.by)")
  }
}

// MARK: - Removed Comment View

struct RemovedCommentView: View {
  var comment: Comment

  private var leadingPadding: CGFloat {
    #if os(iOS)
    24 + CGFloat(comment.depth) * 16
    #elseif os(visionOS)
    32 + CGFloat(comment.depth) * 16
    #endif
  }

  var body: some View {
    VStack(spacing: 0) {
      Text("[Blocked]")
        .font(.custom("Lato-Regular", size: 16, relativeTo: .body))
        #if os(iOS)
        .foregroundColor(Color("subtitleColor").opacity(0.5))
        #elseif os(visionOS)
        .foregroundStyle(.secondary.opacity(0.5))
        #endif
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 15, leading: leadingPadding, bottom: 15, trailing: 30))
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
    .accessibilityLabel("Removed comment")
  }
}

// MARK: - Sensitivity Popover View

struct SensitivityPopoverView: View {
  var moderationStore: ModerationStore
  var classifier: CommentClassifier
  var viewModel: FeedViewModel
  var classifyComments: ([Comment]) -> Void
  var onRequiresAI: () -> Void
  @State private var sliderValue: Double = 5

  private static let levels: [(String, String)] = [
    ("Minimal", "Extreme hate speech only"),
    ("Lenient", "Slurs and direct threats"),
    ("Low", "Clearly offensive content"),
    ("Moderate-Low", "Hateful and abusive language"),
    ("Moderate", "Insults and harassment"),
    ("Moderate-High", "Toxicity and name-calling"),
    ("Strict", "Rude and dismissive comments"),
    ("Very Strict", "Passive-aggressive tone"),
    ("Aggressive", "Banned word list"),
    ("Maximum", "Hide all comments"),
  ]

  private var isEnabled: Bool {
    moderationStore.isModerationActive
  }

  private var showAIWarning: Bool {
    !classifier.isAvailable && moderationStore.sensitivityLevel < 9
  }

  private var warningColor: Color {
    #if os(visionOS)
    Color(red: 1.0, green: 0.6, blue: 0.2).opacity(isEnabled ? 1 : 0.35)
    #else
    Color("accentOrange").opacity(isEnabled ? 1 : 0.35)
    #endif
  }

  var body: some View {
    VStack(spacing: 16) {
      Toggle(isOn: Binding(
        get: { isEnabled },
        set: { newValue in
          withAnimation(.smooth(duration: 0.25)) {
            if newValue {
              moderationStore.unhideOnce = false
              moderationStore.hideOnce = true
              classifyComments(viewModel.comments)
            } else {
              moderationStore.unhideOnce = true
            }
          }
        }
      )) {
        Text("Moderation")
          .font(.custom("Lato-Bold", size: 16, relativeTo: .headline))
      }

      VStack(spacing: 16) {
        Toggle(isOn: Binding(
          get: { moderationStore.hideAlways },
          set: { newValue in
            moderationStore.setHideAlways(newValue)
            if newValue {
              moderationStore.unhideOnce = false
              moderationStore.hideOnce = true
            }
          }
        )) {
          Text("Always On")
            .font(.custom("Lato-Regular", size: 14, relativeTo: .subheadline))
        }

        VStack(spacing: 12) {
          HStack {
            Text("Sensitivity")
              .font(.custom("Lato-Regular", size: 14, relativeTo: .subheadline))
              .foregroundStyle(.secondary)
            Spacer()
            if showAIWarning {
              Button(action: { onRequiresAI() }) {
                Image(systemName: "exclamationmark.triangle.fill")
                  .font(.system(size: 14))
                  .foregroundStyle(warningColor)
              }
              .buttonStyle(.plain)
            }
            Text("\(moderationStore.sensitivityLevel)")
              .font(.custom("Lato-Bold", size: 24, relativeTo: .title))
              .foregroundStyle(showAIWarning ? warningColor : .secondary.opacity(isEnabled ? 1 : 0.35))
              .contentTransition(.numericText())
          }

          VStack(spacing: 4) {
            let index = moderationStore.sensitivityLevel - 1
            Text(Self.levels[max(0, min(index, Self.levels.count - 1))].0)
              .font(.custom("Lato-Bold", size: 14, relativeTo: .subheadline))
              .foregroundStyle(showAIWarning ? warningColor : .primary.opacity(isEnabled ? 1 : 0.35))
              .contentTransition(.numericText())
            Text(showAIWarning
              ? "Requires Apple Intelligence"
              : Self.levels[max(0, min(index, Self.levels.count - 1))].1)
              .font(.custom("Lato-Regular", size: 13, relativeTo: .caption))
              .foregroundStyle(showAIWarning ? warningColor.opacity(0.8) : .secondary.opacity(isEnabled ? 1 : 0.35))
              .contentTransition(.numericText())
          }

          Slider(value: $sliderValue, in: 1...10, step: 1) {
            Text("Sensitivity")
          } minimumValueLabel: {
            Text("1")
              .font(.custom("Lato-Regular", size: 12, relativeTo: .caption2))
              .foregroundStyle(.secondary)
          } maximumValueLabel: {
            Text("10")
              .font(.custom("Lato-Regular", size: 12, relativeTo: .caption2))
              .foregroundStyle(.secondary)
          } onEditingChanged: { editing in
            if !editing && isEnabled {
              // Defer to ensure setSensitivityLevel has completed
              Task { @MainActor in
                moderationStore.flaggedCommentIds.removeAll()
                moderationStore.manuallyUnhiddenCommentIds.removeAll()
                classifyComments(viewModel.comments)
              }
            }
          }
          .tint(showAIWarning ? Color("accentOrange") : (moderationStore.sensitivityLevel >= 9 && !classifier.isAvailable ? .blue : nil))
          .onChange(of: sliderValue) { _, newValue in
            let newLevel = Int(newValue)
            if newLevel != moderationStore.sensitivityLevel {
              withAnimation(.easeInOut(duration: 0.15)) {
                moderationStore.setSensitivityLevel(newLevel)
              }
            }
          }
        }
      }
      .disabled(!isEnabled)
      .opacity(isEnabled ? 1 : 0.35)
    }
    .padding(20)
    .frame(width: 280)
    .onAppear {
      sliderValue = Double(moderationStore.sensitivityLevel)
    }
    .sensoryFeedback(.selection, trigger: moderationStore.sensitivityLevel)
    .presentationCompactAdaptation(.popover)
  }
}

// MARK: - Moderation Alert Modifier

struct ModerationAlertModifier: ViewModifier {
  @Binding var showEnableAIAlert: Bool
  @Binding var blockUserTarget: Comment?
  @Binding var showBlockConfirmAlert: Bool
  @Binding var reportTarget: Comment?
  @Binding var reportReason: String
  @Binding var showReportSentAlert: Bool
  var onBlockHide: (String) -> Void
  var onBlockRemove: (String) -> Void

  func body(content: Content) -> some View {
    content
      .alert("Apple Intelligence Required", isPresented: $showEnableAIAlert) {
        Button("Open Settings") {
          #if os(iOS)
          if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
          }
          #endif
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text("Apple Intelligence is required for sensitivity levels 1-8. Set sensitivity to 9 or higher to use the banned word list instead, which works without Apple Intelligence.")
      }
      .alert("Block \(blockUserTarget?.by ?? "")?", isPresented: .init(
        get: { blockUserTarget != nil && !showBlockConfirmAlert },
        set: { if !$0 && !showBlockConfirmAlert { blockUserTarget = nil } }
      )) {
        Button("Hide User Comments") {
          if let user = blockUserTarget {
            onBlockHide(user.by)
          }
          blockUserTarget = nil
        }
        Button("Remove User Comments") {
          showBlockConfirmAlert = true
        }
        Button("Cancel", role: .cancel) { blockUserTarget = nil }
      }
      .alert("Are you sure? This cannot be undone.", isPresented: $showBlockConfirmAlert) {
        Button("Block Forever", role: .destructive) {
          if let user = blockUserTarget {
            onBlockRemove(user.by)
          }
          blockUserTarget = nil
        }
        Button("Cancel", role: .cancel) { blockUserTarget = nil }
      } message: {
        Text("All comments from \(blockUserTarget?.by ?? "this user") will be permanently hidden and you will not see their future comments.")
      }
      .sheet(item: $reportTarget) { comment in
        ReportSheet(comment: comment, reason: $reportReason) {
          showReportSentAlert = true
        }
      }
      .alert("Report Sent", isPresented: $showReportSentAlert) {
        Button("OK", role: .cancel) {}
      } message: {
        Text("Thank you for your report. We'll review this comment shortly.")
      }
  }
}

// MARK: - Report Sheet

struct ReportSheet: View {
  @Environment(\.dismiss) private var dismiss
  var comment: Comment
  @Binding var reason: String
  var onReported: () -> Void
  @State private var isSubmitting = false

  private var isReasonEmpty: Bool {
    reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 16) {
        Text("Why are you reporting this comment?")
          .font(.custom("Lato-Bold", size: 18, relativeTo: .headline))
        Text("Comment by \(comment.by)")
          .font(.custom("Lato-Regular", size: 15, relativeTo: .subheadline))
          .foregroundStyle(.secondary)
        TextField("Reason", text: $reason, axis: .vertical)
          .lineLimit(3...6)
          .font(.custom("Lato-Regular", size: 16, relativeTo: .body))
          .padding(12)
          .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
          #if os(visionOS)
          .overlay(RoundedRectangle(cornerRadius: 12).stroke(.secondary.opacity(0.5), lineWidth: 1))
          #else
          .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color("borderColor"), lineWidth: 1))
          #endif
          .disabled(isSubmitting)
        Spacer()
      }
      .padding(24)
      .navigationTitle("Report Comment")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            reason = ""
            dismiss()
          }
          .disabled(isSubmitting)
        }
        ToolbarItem(placement: .confirmationAction) {
          if isSubmitting {
            ProgressView()
          } else {
            Button("Report") {
              Task {
                isSubmitting = true
                await ReportService.report(comment: comment, reason: reason)
                isSubmitting = false
                reason = ""
                dismiss()
                onReported()
              }
            }
            .disabled(isReasonEmpty)
          }
        }
      }
      .interactiveDismissDisabled(isSubmitting)
    }
    .presentationDetents([.medium])
  }
}
