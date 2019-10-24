//
//  FeedView.swift
//  Hackery
//
//  Created by Tim Shim on 6/10/19.
//  Copyright © 2019 Tim Shim. All rights reserved.
//

import SwiftUI
import SafariServices

private let feedController = FeedController()

struct CommentButton: View {
    var body: some View {
        Text(verbatim: "COMMENTS")
            .font(.custom("Lato-Regular", size: 13))
            .foregroundColor(Color("titleColor"))
            .padding(EdgeInsets(top: 10, leading: 15, bottom: 10, trailing: 15))
            .border(Color("borderColor"), width: 1)
    }
}

struct StoryView: View {
    var story: Story

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(self.story.title)
                .font(.custom("Lato-Bold", size: 18))
                .bold()
                .foregroundColor(Color("titleColor"))
                .padding(.bottom, 3)
            HStack(alignment: .bottom) {
                VStack(alignment: .leading) {
                    Text("\(self.story.timeAgo)")
                        .font(.custom("Lato-Regular", size: 15))
                        .foregroundColor(Color("subtitleColor"))
                        .lineLimit(1)
                    Text("\(self.story.score) points")
                        .font(.custom("Lato-Regular", size: 15))
                        .foregroundColor(Color("subtitleColor"))
                        .lineLimit(1)
                    Text("By \(self.story.by)")
                        .font(.custom("Lato-Regular", size: 15))
                        .foregroundColor(Color("subtitleColor"))
                        .lineLimit(1)
                }
                Spacer()
                if self.story.kids.count > 0 {
                    NavigationLink(destination: CommentsView(fc: feedController, story: self.story)) {
                        CommentButton()
                    }
                }
            }
        }
        .padding()
    }
}

struct FeedView: View {
    @ObservedObject private var fc = feedController
    private let width = UIScreen.main.bounds.width - 20

    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                Group {
                    ForEach(self.fc.stories) { story in
                        StoryView(story: story)
                            .frame(width: self.width, alignment: .leading)
                            .background(Color("cardBg"))
                            .onTapGesture {
                                self.fc.showStory(story)
                        }
                        Spacer()
                            .frame(width: self.width, height: CGFloat(1))
                            .background(Color("borderColor"))
                    }
                }
                .cornerRadius(10)
            }
            .frame(width: self.width)
            .navigationBarTitle(Text("Hacker News"))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
