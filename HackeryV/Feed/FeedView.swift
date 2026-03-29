//
//  FeedView.swift
//  HackeryV
//
//  Created by Tim Shim on 6/8/23.
//  Copyright © 2023 Tim Shim. All rights reserved.
//

import SwiftUI

struct FeedView: View {
  @Environment(FeedViewModel.self) private var viewModel

  var body: some View {
    NavigationStack {
      ZStack {
        if viewModel.isLoading {
          LoaderView()
        }
        StoryGridView()
      }
      .overlay(alignment: .bottom) {
        if let error = viewModel.error {
          ErrorBannerView(message: error)
        }
      }
    }
    .ornament(attachmentAnchor: .scene(.bottom), ornament: {
      RefreshButtonView(tapped: loadTopStories)
        .glassBackgroundEffect()
    })
    .onAppear {
      loadTopStories()
    }
  }

  private func loadTopStories() {
    Task {
      await viewModel.loadTopStories()
    }
  }
}

struct StoryGridView: View {
  @Environment(FeedViewModel.self) private var viewModel

  let columns = [
    GridItem(.adaptive(minimum: 400), alignment: .top)
  ]

  var body: some View {
    ScrollView {
      LazyVGrid(columns: columns) {
        ForEach(viewModel.stories) { story in
          StoryView(story: story)
            .padding(8)
            .background(.regularMaterial, in: .rect(cornerRadius: 32))
            .contentShape(.hoverEffect, .rect(cornerRadius: 32))
            .hoverEffect()
            .onTapGesture {
              if let url = URL(string: story.url), !story.url.isEmpty {
                UIApplication.shared.open(url)
              }
            }
        }
      }
    }
  }
}

struct StoryButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding(8)
      .background(.regularMaterial, in: .rect(cornerRadius: 32))
      .hoverEffect()
  }
}

struct RefreshButtonView: View {
  var tapped: (() -> Void)?

  var body: some View {
    Button(action: {
      tapped?()
    }) {
      Image(systemName: "arrow.clockwise")
        .font(.system(size: 24, weight: .bold, design: .rounded))
        .frame(width: 60, height: 60)
        .padding()
    }
    .buttonStyle(.plain)
  }
}

struct LoaderView: View {
  var body: some View {
    VStack {
      Spacer()
      ProgressView()
      Spacer()
    }
  }
}

struct ErrorBannerView: View {
  let message: String

  var body: some View {
    Text(message)
      .font(.system(.footnote, design: .rounded))
      .foregroundColor(.white)
      .padding()
      .background(Color.red.opacity(0.85), in: RoundedRectangle(cornerRadius: 12))
      .padding()
      .transition(.move(edge: .bottom).combined(with: .opacity))
  }
}
