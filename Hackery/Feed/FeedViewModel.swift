//
//  FeedViewModel.swift
//  Hackery
//
//  Created by Tim Shim on 6/10/19.
//  Copyright © 2019 Tim Shim. All rights reserved.
//

import SwiftUI
import SwiftSoup

final class FeedViewModel: ObservableObject {

    @Published var stories = [Story]()
    @Published var comments = [Comment]()
    @Published var isLoading = false

    func loadTopStories() {
        guard let url = URL(string: "https://hacker-news.firebaseio.com/v0/topstories.json") else { return }
        
        self.isLoading = true
        self.stories.removeAll()
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, error == nil {
                do {
                    if let storyIds = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [Int] {
                        self.loadStories(Array(storyIds.prefix(100)))
                    }
                } catch {
                    print("Error parsing stories JSON")
                }
            }
        }
        
        task.resume()
    }
    
    private func loadStories(_ storyIds: [Int]) {
        for id in storyIds {
            guard let url = URL(string: "https://hacker-news.firebaseio.com/v0/item/\(id).json") else { return }
            
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data, error == nil {
                    do {
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
                            
                            DispatchQueue.main.async {
                                self.stories.append(story)
                                self.isLoading = false
                            }
                        }
                    } catch {
                        print("Error parsing story JSON")
                    }
                }
            }
            
            task.resume()
        }
    }

    func loadComments(story: Story) {
        self.isLoading = true
        self.comments.removeAll()
        
        for id in story.kids {
            guard let url = URL(string: "https://hacker-news.firebaseio.com/v0/item/\(id).json") else { return }
            
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data, error == nil {
                    do {
                        if let item = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
//                            if let deleted = item["deleted"] as? Int, deleted == 1 { return }
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
                            
                            DispatchQueue.main.async {
                                self.comments.append(comment)
                                self.isLoading = false
                            }
                        }
                    } catch {
                        print("Error parsing comment JSON")
                    }
                }
            }
            
            task.resume()
        }
    }

}
