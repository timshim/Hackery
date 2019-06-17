//
//  CommentsView.swift
//  Hackery
//
//  Created by Tim Shim on 6/17/19.
//  Copyright © 2019 Tim Shim. All rights reserved.
//

import SwiftUI
import Combine

struct CommentView: View {
    var comment: Comment

    var body: some View {
        Text("\(comment.text)\n\n\(comment.by) \(comment.timeAgo.lowercased())")
            .font(.custom("Lato-Regular", size: 16))
            .color(Color("titleColor"))
            .lineLimit(nil)
            .padding()
    }
}

struct CommentsView : View {
    @State var fc: FeedController
    var story: Story

    var body: some View {
        List {
            VStack(alignment: .leading, spacing: 5) {
                Text(story.title)
                    .font(.custom("Lato-Bold", size: 18))
                    .bold()
                    .color(Color("titleColor"))
                    .lineLimit(nil)
                    .padding(.bottom, 3)
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
                }
            }
            .padding()
            ForEach(fc.comments.identified(by: \.self)) { comment in
                CommentView(comment: comment)
            }
        }
        .navigationBarItem(title: Text(""), titleDisplayMode: .inline, hidesBackButton: false)
        .colorScheme(.light)
        .onAppear {
            self.fc.loadComments(story: self.story)
        }
    }
}
