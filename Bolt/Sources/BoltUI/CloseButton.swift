// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

public struct CloseButton: View {
    @Environment(\.dismiss) private var dismiss: DismissAction

    public init(_ titleKey: LocalizedStringKey = "", systemImage: String = "xmark") {
        self.titleKey = titleKey
        self.systemImage = systemImage
    }

    private let titleKey: LocalizedStringKey
    private let systemImage: String

    // MARK: View
    public var body: some View {
        Button(action: { dismiss() }) {
            Label(titleKey, systemImage: systemImage)
        }
    }
}

#Preview("Close Button") {
    CloseButton()
        .padding()
}
