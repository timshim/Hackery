//
//  HackeryWidgetsBundle.swift
//  HackeryWidgets
//
//  Created by Tim Shim on 10/4/26.
//  Copyright © 2026 Tim Shim. All rights reserved.
//

import WidgetKit
import SwiftUI

@main
struct HackeryWidgetsBundle: WidgetBundle {
  var body: some Widget {
    TopStoryWidget()
    TopStoriesWidget()
    BookmarksWidget()
  }
}
