// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

extension View {

    /// Select appropriate text style for any `View`.
    public func textStyle(_ style: Font.Style, isDynamic: Bool = true) -> some View {
        modifier(TextStyleViewModifier(style, isDynamic: isDynamic))
    }
}

struct TextStyleViewModifier: ViewModifier {
    let style: Font.Style
    let isDynamic: Bool

    init(_ style: Font.Style, isDynamic: Bool) {
        self.style = style
        self.isDynamic = isDynamic
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize: DynamicTypeSize

    // MARK: ViewModifier
    func body(content: Content) -> some View {
        content
            .font(.bolt(style, size: isDynamic ? dynamicTypeSize : .default))
            .kerning(style.kerning)
            .lineSpacing(style.lineSpacing / 2.0)
            .frame(minHeight: style.minHeight)
    }
}

#Preview("Text Style View Modifier") {
    ScrollView {
        VStack {
            ForEach(Font.Style.allCases) { style in
                TextStylePreview(style: style)
                    .padding()
            }
        }
    }
}

private struct TextStylePreview: View {
    let style: Font.Style

    // MARK: View
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(style.description)
                    .textStyle(.subhead)
                    .foregroundStyle(.secondary)
                Text(.quickBrownFox)
                    .textStyle(style)
            }
            Spacer()
        }
    }
}

private extension Font.Style {
    var minHeight: CGFloat { fixedSize + lineSpacing }
}
