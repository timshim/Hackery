//
//  StoryView.swift
//  Hackery
//
//  Created by Tim Shim on 31/5/20.
//  Copyright © 2020 Tim Shim. All rights reserved.
//

import SwiftUI

struct StoryView: View {
    @EnvironmentObject private var viewModel: FeedViewModel
    
    var story: Story
    @State private var showComments = false

    var body: some View {
        ZStack {
            Color("cardBg")
            VStack(alignment: .leading, spacing: 5) {
                Text(self.story.title)
                    .font(.custom("Lato-Bold", size: 18))
                    .foregroundColor(Color("titleColor"))
                    .padding(EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16))
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
                        Button(action: {
                            viewModel.comments.removeAll()
                            viewModel.loadComments(story: self.story)
                            self.showComments = true
                        }) {
                            CommentButton(count: story.kids.count)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .sheet(isPresented: $showComments) {
                            CommentsView(story: self.story).environmentObject(viewModel)
                        }
                    }
                }
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
            }
        }
    }
}

//struct StoryView_Previews: PreviewProvider {
//    static var previews: some View {
//        var story = Story()
//        story.title = "Hello world"
//        story.timeAgo = "1 hour ago"
//        story.score = 99
//        story.by = "Tim Shim"
//        return StoryView(story: story)
//    }
//}
