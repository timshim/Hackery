//
//  CommentsView.swift
//  Hackery
//
//  Created by Tim Shim on 6/17/19.
//  Copyright © 2019 Tim Shim. All rights reserved.
//

import SwiftUI

struct TextView: UIViewRepresentable {
    let text: String

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.dataDetectorTypes = .link
        tv.isEditable = false
        tv.text = text
        tv.textColor = UIColor(named: "titleColor")
        tv.font = UIFont(name: "Lato-Regular", size: 16)
        tv.isScrollEnabled = false
        tv.textContainer.lineBreakMode = .byWordWrapping
        return tv
    }
    func updateUIView(_ uiView: UITextView, context: Context) {
    }
}

struct CommentView: View {
    var comment: Comment

    var body: some View {
//        Text lines do not wrap as intended
//        TextView(text: "\(comment.text)\n\n\(comment.by) \(comment.timeAgo.lowercased())")
//            .padding(10)
        Text("\(comment.text)\n\n\(comment.by) \(comment.timeAgo.lowercased())")
            .font(.custom("Lato-Regular", size: 16))
            .color(Color("titleColor"))
            .lineLimit(nil)
            .padding(15)
    }
}

struct CommentsView : View {
    @State var fc: FeedController
    var story: Story

    var body: some View {
        VStack(alignment: .leading) {
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
            .padding(EdgeInsets(top: 30, leading: 30, bottom: 0, trailing: 30))
            List(fc.comments.identified(by: \.self)) { comment in
                CommentView(comment: comment)
            }
            .onAppear {
                self.fc.loadComments(story: self.story)
            }
        }
        .navigationBarTitle(Text(""), displayMode: .inline)
        .background(Color("cardBg"))
        .colorScheme(.light)
    }
}
