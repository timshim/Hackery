//
//  StoryView.swift
//  HackeryV
//
//  Created by Tim Shim on 6/8/23.
//  Copyright © 2023 Tim Shim. All rights reserved.
//

import SwiftUI

struct StoryView: View {
    @EnvironmentObject private var viewModel: FeedViewModel
    @State private var showComments = false
    
    var story: Story
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                Text(self.story.title)
                    .multilineTextAlignment(.leading)
                    .font(.system(.title, design: .rounded))
                    .padding(.bottom, 16)
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading) {
                        Text("\(self.story.timeAgo)")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Text("\(self.story.score) points")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Text("By \(self.story.by)")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    if self.story.kids.count > 0 {
                        Button(action: {
                            self.showComments = true
                        }) {
                            CommentButton(count: story.kids.count)
                        }
                        .navigationDestination(isPresented: $showComments, destination: {
                            CommentsView(story: self.story).environmentObject(viewModel)
                        })
                        .buttonStyle(.plain)
                        .hoverEffect()
                    }
                }
            }
        }
        .padding(16)
    }
}
