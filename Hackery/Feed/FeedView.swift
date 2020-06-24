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
    @EnvironmentObject private var fc: FeedController
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("background")
                    .edgesIgnoringSafeArea(.all)
                ScrollView {
                    LazyVStack {
                        ForEach(self.fc.stories, id: \.id) { story in
                            NavigationLink(destination: SafariView(url: URL(string: story.url)!)) {
                                StoryView(story: story)
                                    .environmentObject(self.fc)
                            }
                        }
                        .cornerRadius(10)
                        .padding(EdgeInsets(top: 0, leading: 8, bottom: -5, trailing: 8))
                    }
                }
                .padding(.top, 50)
                .edgesIgnoringSafeArea(.top)
                VStack {
                    Spacer()
                    Button(action: {
                        self.fc.reload()
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
                if fc.isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .edgesIgnoringSafeArea(.all)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
