// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

///Wrapping horizontal views do not exist in SwiftUI. This fills the gap
///- Parameters:
///  - horizontalSpacing: defaults to 6 pixels but customizeable
///  - verticalSpacing: defaults to 5 pixels but customizeable
///- Returns:
///Layout for subviews based on the spacing and size limitations
struct HStackWrap: Layout {
    private let horizontalSpacing: CGFloat
    private let verticalSpacing: CGFloat

    public init(
        horizontalSpacing: CGFloat = 6,
        verticalSpacing: CGFloat = 5
    ) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        var width = 0.0
        var height = 0.0
        var rowHeight = 0.0
        var rowWidth = 0.0
        let maxWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if rowWidth + size.width > maxWidth {
                width = max(rowWidth, maxWidth)
                height += rowHeight + verticalSpacing
                rowWidth = 0
                rowHeight = 0
            }

            rowWidth += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }

        width = max(width, rowWidth)
        height += rowHeight

        return CGSize(width: width, height: height)
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        let maxWidth = bounds.maxX

        for subview in subviews {
            let size = subview.dimensions(in: .unspecified)

            if currentX + size.width > maxWidth {
                currentY += size.height + verticalSpacing
                currentX = bounds.minX
            }

            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                proposal: .unspecified
            )

            currentX += size.width + horizontalSpacing
        }
    }
}
