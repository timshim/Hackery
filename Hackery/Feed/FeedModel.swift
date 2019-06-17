//
//  FeedModel.swift
//  Hackery
//
//  Created by Tim Shim on 6/17/19.
//  Copyright © 2019 Tim Shim. All rights reserved.
//

struct Story: Hashable {
    var id = 0
    var by = ""
    var descendants = 0
    var kids = [Int]()
    var score = 0
    var time = 0
    var timeAgo = ""
    var title = ""
    var type = "story"
    var url = ""
}

struct Comment: Hashable {
    var by = ""
    var id = 0
    var kids = [Int]()
    var parent = 0
    var text = ""
    var time = 0
    var timeAgo = ""
    var type = "comment"
}
