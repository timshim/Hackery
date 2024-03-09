//
//  CommentsView.swift
//  HackeryV
//
//  Created by Tim Shim on 6/8/23.
//  Copyright © 2023 Tim Shim. All rights reserved.
//

import SwiftUI

struct CommentsView: View {
    @EnvironmentObject private var viewModel: FeedViewModel
    
    var story: Story

    var body: some View {
        ZStack {
            Color("cardBg")
                .edgesIgnoringSafeArea(.all)
            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(story.title)
                        .multilineTextAlignment(.leading)
                        .font(.system(.title, design: .rounded))
                        .padding(.bottom, 3)
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading) {
                            Text("\(story.timeAgo)")
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Text("\(story.score) points")
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Text("By \(story.by)")
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.horizontal, 32)
                ScrollView {
                    LazyVStack {
                        ForEach(viewModel.comments, id: \.id) { comment in
                            CommentView(comment: comment)
                        }
                    }
                }
                .edgesIgnoringSafeArea(.top)
            }
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .edgesIgnoringSafeArea(.all)
            }
        }
        .onAppear {
            loadComments(for: story)
        }
    }
    
    private func loadComments(for story: Story) {
        Task {
            await viewModel.loadComments(for: story)
        }
    }
}

struct CommentView: View {
    var comment: Comment
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                Text(comment.text)
                    .multilineTextAlignment(.leading)
                    .font(.system(.body, design: .rounded))
                    .padding(EdgeInsets(top: 15, leading: 30, bottom: 15, trailing: 30))
                Text("\(comment.by) \(comment.timeAgo.lowercased())")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(EdgeInsets(top: 5, leading: 30, bottom: 12, trailing: 30))
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)
            }
        }
        
    }
}
