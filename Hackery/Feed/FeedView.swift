//
//  FeedView.swift
//  Hackery
//
//  Created by Tim Shim on 6/10/19.
//  Copyright © 2019 Tim Shim. All rights reserved.
//

import SwiftUI

private let feedController = FeedController()

struct StatusBarView: View {
    var body: some View {
        Spacer()
            .frame(width: UIScreen.main.bounds.width, height: 2)
            .edgesIgnoringSafeArea([.top, .bottom])
    }
}

struct CommentButton: View {
    var body: some View {
        Text("COMMENTS")
            .font(.custom("Lato-Regular", size: 13))
            .color(Color("titleColor"))
            .padding(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
            .border(Color("borderColor"), width: 1, cornerRadius: 5)
    }
}

struct StoryView: View {
    var story: Story

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(story.title)
                .font(.custom("Lato-Bold", size: 18))
                .bold()
                .color(Color("titleColor"))
                .padding(.bottom, 3)
                .lineLimit(nil)
                .frame(minHeight: 24, idealHeight: 48, maxHeight: 96)
            HStack(alignment: .bottom) {
                VStack(alignment: .leading) {
                    Text("\(story.timeAgo)")
                        .font(.custom("Lato-Regular", size: 15))
                        .color(Color("subtitleColor"))
                        .lineLimit(1)
                        .padding(.bottom, -7)
                    Text("\(story.score) points")
                        .font(.custom("Lato-Regular", size: 15))
                        .color(Color("subtitleColor"))
                        .lineLimit(1)
                        .padding(.bottom, -7)
                    Text("By \(story.by)")
                        .font(.custom("Lato-Regular", size: 15))
                        .color(Color("subtitleColor"))
                        .lineLimit(1)
                }
                Spacer()
                if story.kids.count > 0 {
                    NavigationButton(destination: CommentsView(fc: feedController, story: story).background(Color.white)) {
                        CommentButton()
                    }
                }
            }
        }
        .padding()
    }
}

struct FeedView: View {
    @ObjectBinding private var fc = feedController
    private let width = UIScreen.main.bounds.width - 20

    var body: some View {
        NavigationView {
            StatusBarView()
            ScrollView(showsVerticalIndicator: false) {
                Group {
                    ForEach(fc.stories.identified(by: \.self)) { story in
                        StoryView(story: story)
                            .frame(width: self.width, alignment: .leading)
                            .background(Color("cardBg"))
                            .tapAction {
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
        .colorScheme(.dark)
    }
}
