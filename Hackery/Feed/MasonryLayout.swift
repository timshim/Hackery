//
//  MasonryLayout.swift
//  Hackery
//
//  Created by Tim Shim on 3/4/26.
//

import SwiftUI

#if os(iOS)
struct MasonryLayout: Layout {
  var columns: Int
  var spacing: CGFloat

  init(columns: Int = 2, spacing: CGFloat = 8) {
    self.columns = columns
    self.spacing = spacing
  }

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let width = proposal.width ?? 300
    let columnWidth = (width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
    var columnHeights = Array(repeating: CGFloat.zero, count: columns)

    for subview in subviews {
      let shortest = columnHeights.enumerated().min(by: { $0.element < $1.element })!.offset
      let size = subview.sizeThatFits(.init(width: columnWidth, height: nil))
      columnHeights[shortest] += size.height + spacing
    }

    let maxHeight = columnHeights.max() ?? 0
    return CGSize(width: width, height: max(maxHeight - spacing, 0))
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    let columnWidth = (bounds.width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
    var columnHeights = Array(repeating: CGFloat.zero, count: columns)

    for subview in subviews {
      let shortest = columnHeights.enumerated().min(by: { $0.element < $1.element })!.offset
      let x = bounds.minX + CGFloat(shortest) * (columnWidth + spacing)
      let y = bounds.minY + columnHeights[shortest]

      let size = subview.sizeThatFits(.init(width: columnWidth, height: nil))
      subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: .init(width: columnWidth, height: size.height))

      columnHeights[shortest] += size.height + spacing
    }
  }
}
#endif
