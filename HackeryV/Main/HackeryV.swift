//
//  HackeryV.swift
//  HackeryV
//
//  Created by Tim Shim on 6/8/23.
//  Copyright © 2023 Tim Shim. All rights reserved.
//

import SwiftUI

@main
struct HackeryV: App {    
    var body: some Scene {
        WindowGroup {
            FeedView()
                .frame(minWidth: 500, maxWidth: 500)
                .padding()
                .environmentObject(FeedViewModel())
        }
        .defaultSize(width: 500, height: 800)
        .windowResizability(.contentSize)
    }
}
