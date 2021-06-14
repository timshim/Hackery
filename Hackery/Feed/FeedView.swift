//
//  FeedView.swift
//  Hackery
//
//  Created by Tim Shim on 6/10/19.
//  Copyright © 2019 Tim Shim. All rights reserved.
//

import SwiftUI
import SafariServices

struct FeedView: View {
    @EnvironmentObject private var viewModel: FeedViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("background")
                    .edgesIgnoringSafeArea(.all)
                if viewModel.isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .edgesIgnoringSafeArea(.all)
                }
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
                VStack {
                    Color("background")
                        .frame(maxWidth: .infinity, minHeight: 50, idealHeight: 50, maxHeight: 50, alignment: .top)
                    Spacer()
                }
                .edgesIgnoringSafeArea(.all)
                VStack {
                    Spacer()
                    Button(action: {
                        viewModel.loadTopStories()
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
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.loadTopStories()
        }
    }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
