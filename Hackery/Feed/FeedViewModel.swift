//
//  FeedViewModel.swift
//  Hackery
//
//  Created by Tim Shim on 6/10/19.
//  Copyright © 2019 Tim Shim. All rights reserved.
//

import SwiftUI
import SwiftSoup

@MainActor
final class FeedViewModel: ObservableObject {

    @Published var stories = [Story]()
    @Published var comments = [Comment]()
    @Published var isLoading = false

    func loadTopStories() async {
        guard let url = URL(string: "https://hacker-news.firebaseio.com/v0/topstories.json") else { return }
        
        isLoading = true
        stories.removeAll()
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let storyIds = try JSONDecoder().decode([Int].self, from: data)
            Task {
                await loadStories(Array(storyIds.prefix(100)))
            }
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    private func loadStories(_ storyIds: [Int]) async {
        for id in storyIds {
            Task {
                guard let url = URL(string: "https://hacker-news.firebaseio.com/v0/item/\(id).json") else { return }
                
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let item = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
                        guard let id = item["id"] as? Int else { return }
                        guard let by = item["by"] as? String else { return }
                        guard let score = item["score"] as? Int else { return }
                        guard let time = item["time"] as? Int else { return }
                        guard let title = item["title"] as? String else { return }
                        guard let type = item["type"] as? String else { return }
                        
                        let descendants = item["descendants"] as? Int ?? 0
                        let kids = item["kids"] as? [Int] ?? []
                        let url = item["url"] as? String ?? ""
                        
                        let timeAgo = Date(timeIntervalSince1970: TimeInterval(time)).relativeTime
                        
                        let story = Story(id: id, by: by, descendants: descendants, kids: kids, score: score, time: time, timeAgo: timeAgo, title: title, type: type, url: url)
                        
                        stories.append(story)
                        isLoading = false
                    }
                } catch let error {
                    print(error.localizedDescription)
                }
            }
        }
    }

    func loadComments(for story: Story) async {
        isLoading = true
        comments.removeAll()
        
        for id in story.kids {
            Task {
                guard let url = URL(string: "https://hacker-news.firebaseio.com/v0/item/\(id).json") else { return }
                
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let item = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
                        guard let by = item["by"] as? String else { return }
                        guard let id = item["id"] as? Int else { return }
                        guard let parent = item["parent"] as? Int else { return }
                        guard let text = item["text"] as? String else { return }
                        guard let time = item["time"] as? Int else { return }
                        guard let type = item["type"] as? String else { return }
                        
                        var moreComments = [Int]()
                        if let kids = item["kids"] as? [Int] {
                            moreComments = kids
                        }
                        
                        let timeAgo = Date(timeIntervalSince1970: TimeInterval(time)).relativeTime
                        
                        let parsedText = try SwiftSoup.parse(text.replacingOccurrences(of: "<p>", with: "<p>*newline*")).text().replacingOccurrences(of: "*newline*", with: "\n\n")
                        
                        let comment = Comment(by: by, id: id, kids: moreComments, parent: parent, text: parsedText, time: time, timeAgo: timeAgo, type: type)
                        
                        comments.append(comment)
                        isLoading = false
                    }
                } catch let error {
                    print(error.localizedDescription)
                }
            }
        }
    }

}
