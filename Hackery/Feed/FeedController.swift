//
//  FeedController.swift
//  Hackery
//
//  Created by Tim Shim on 6/10/19.
//  Copyright © 2019 Tim Shim. All rights reserved.
//

import Firebase
import SwiftUI
import Combine
import SafariServices
import SwiftSoup

final class FeedController: BindableObject {

    var willChange = PassthroughSubject<FeedController, Never>()

    var stories = [Story]() {
        didSet {
            willChange.send(self)
        }
    }
    var comments = [Comment]() {
        didSet {
            willChange.send(self)
        }
    }
    private let topstories = Database.database().reference().child("v0").child("topstories")
    private let item = Database.database().reference().child("v0").child("item")

    init() {
        topstories.queryLimited(toFirst: 100).observeSingleEvent(of: .value) { snapshot in
            if let ids = snapshot.value as? [Int] {
                for id in ids {
                    self.item.child("\(id)").observeSingleEvent(of: .value) { [weak self] itemSnap in
                        if let item = itemSnap.value as? [String: Any] {
                            guard let id = item["id"] as? Int else { return }
                            guard let by = item["by"] as? String else { return }
                            guard let descendants = item["descendants"] as? Int else { return }
                            guard let kids = item["kids"] as? [Int] else { return }
                            guard let score = item["score"] as? Int else { return }
                            guard let time = item["time"] as? Int else { return }
                            guard let title = item["title"] as? String else { return }
                            guard let type = item["type"] as? String else { return }
                            guard let url = item["url"] as? String else { return }

                            let timeAgo = Date(timeIntervalSince1970: TimeInterval(time)).relativeTime

                            let story = Story(id: id, by: by, descendants: descendants, kids: kids, score: score, time: time, timeAgo: timeAgo, title: title, type: type, url: url)
                            self?.stories.append(story)
                            print("Story added: \(story)")
                        }
                    }
                }
            }
        }
    }

    func showStory(_ story: Story) {
        if let url = URL(string: story.url) {
            print(url)
            UIApplication.shared.open(url)
        }
    }

    func loadComments(story: Story) {
        var loadedComments = [Comment]()
        var kidsCount = story.kids.count
        for kid in story.kids {
            self.item.child("\(kid)").observeSingleEvent(of: .value) { snapshot in
                if let value = snapshot.value as? [String: Any] {
                    if let deleted = value["deleted"] as? Int, deleted == 1 {
                        kidsCount -= 1
                    }
                    guard let by = value["by"] as? String else { print("error by"); return }
                    guard let id = value["id"] as? Int else { print("error id"); return }
                    guard let parent = value["parent"] as? Int else { print("error parent"); return }
                    guard let text = value["text"] as? String else { print("error text"); return }
                    guard let time = value["time"] as? Int else { print("error time"); return }
                    guard let type = value["type"] as? String else { print("error type"); return }

                    var moreComments = [Int]()
                    if let kids = value["kids"] as? [Int] {
                        moreComments = kids
                    }

                    let timeAgo = Date(timeIntervalSince1970: TimeInterval(time)).relativeTime

                    let parsedText = try! SwiftSoup.parse(text.replacingOccurrences(of: "<p>", with: "<p>*newline*")).text().replacingOccurrences(of: "*newline*", with: "\n\n")

                    let comment = Comment(by: by, id: id, kids: moreComments, parent: parent, text: parsedText, time: time, timeAgo: timeAgo, type: type)
                    loadedComments.append(comment)

                    if loadedComments.count == kidsCount {
                        self.comments = loadedComments.sorted { $0.time > $1.time }
                    }
                }
            }
        }
    }

}
