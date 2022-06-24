//
//  FeedView.swift
//  Hackery
//
//  Created by Tim Shim on 6/10/19.
//  Copyright © 2019 Tim Shim. All rights reserved.
//

import SwiftUI

struct FeedView: View {
    @EnvironmentObject private var viewModel: FeedViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundView()
                if viewModel.isLoading {
                    LoaderView()
                }
                ContentView(viewModel: viewModel)
                StatusBarView()
                ButtonView(tapped: loadTopStories)
            }
            .navigationBarHidden(true)
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
            .edgesIgnoringSafeArea(.all)
    }
}

struct ContentView: View {
    @ObservedObject var viewModel: FeedViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(viewModel.stories, id: \.id) { story in
                    if let storyUrl = story.url, let url = URL(string: storyUrl) {
                        NavigationLink(destination: SafariView(url: url)) {
                            StoryView(story: story)
                                .environmentObject(viewModel)
                        }
                    }
                }
                .cornerRadius(10)
                .padding(EdgeInsets(top: 0, leading: 8, bottom: -5, trailing: 8))
            }
        }
        .padding(.top, 50)
        .edgesIgnoringSafeArea(.top)
    }
}

struct StatusBarView: View {
    var body: some View {
        VStack {
            Color("background")
                .frame(maxWidth: .infinity, minHeight: 50, idealHeight: 50, maxHeight: 50, alignment: .top)
            Spacer()
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct ButtonView: View {
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
            .background(Circle().foregroundColor(Color("cardBg")).frame(width: 60, height: 60))
            .padding()
            .shadow(color: Color("shadow"), radius: 20, x: 0, y: 20)
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
        .edgesIgnoringSafeArea(.all)
    }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
