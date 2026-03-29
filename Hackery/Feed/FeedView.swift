//
//  FeedView.swift
//  Hackery
//
//  Created by Tim Shim on 6/10/19.
//  Copyright © 2019 Tim Shim. All rights reserved.
//

import SwiftUI

struct FeedView: View {
  @Environment(FeedViewModel.self) private var viewModel

  var body: some View {
    NavigationStack {
      ZStack {
        BackgroundView()
        if viewModel.isLoading {
          LoaderView()
        }
        StoryListView()
        StatusBarView()
        RefreshButtonView(tapped: loadTopStories)
      }
      .navigationBarHidden(true)
      .overlay(alignment: .bottom) {
        if let error = viewModel.error {
          ErrorBannerView(message: error)
        }
      }
    }
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

struct BackgroundView: View {
  var body: some View {
    Color("background")
      .ignoresSafeArea()
  }
}

struct StoryListView: View {
  @Environment(FeedViewModel.self) private var viewModel

  var body: some View {
    ScrollView {
      LazyVStack {
        ForEach(viewModel.stories) { story in
          if let url = URL(string: story.url), !story.url.isEmpty {
            NavigationLink(destination: SafariView(url: url)) {
              StoryView(story: story)
            }
          } else {
            StoryView(story: story)
          }
        }
        .cornerRadius(16)
        .padding(EdgeInsets(top: 0, leading: 8, bottom: -5, trailing: 8))
      }
    }
  }
}

struct StatusBarView: View {
  var body: some View {
    GeometryReader { proxy in
      Color("background")
        .frame(maxWidth: .infinity)
        .frame(height: proxy.safeAreaInsets.top)
        .ignoresSafeArea()
    }
  }
}

struct RefreshButtonView: View {
  var tapped: (() -> Void)?

  var body: some View {
    VStack {
      Spacer()
      Button(action: {
        tapped?()
      }) {
        Image(systemName: "arrow.clockwise")
          .font(.system(size: 24, weight: .bold, design: .rounded))
          .foregroundColor(Color("titleColor"))
          .padding(.bottom, 6)
      }
      .frame(width: 60, height: 60)
      .glassEffect(.clear)
    }
  }
}

struct LoaderView: View {
  var body: some View {
    VStack {
      Spacer()
      ProgressView()
      Spacer()
    }
    .ignoresSafeArea()
  }
}

struct ErrorBannerView: View {
  let message: String

  var body: some View {
    Text(message)
      .font(.custom("Lato-Regular", size: 14))
      .foregroundColor(.white)
      .padding()
      .background(Color.red.opacity(0.85), in: RoundedRectangle(cornerRadius: 12))
      .padding()
      .transition(.move(edge: .bottom).combined(with: .opacity))
  }
}
