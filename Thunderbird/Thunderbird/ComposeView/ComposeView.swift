// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Core

struct ComposeView: View {
    @State var email: Email?

    var body: some View {
        EmailBodyView(email: email, editable: true)
            .toolbar {
                ToolbarItem(placement: .trailing) {
                    Button(action: {

                    }) {
                        Image(systemName: "archivebox")
                            .foregroundStyle(.foreground)
                    }
                }
            }
    }
}

private extension ToolbarItemPlacement {
    static var trailing: Self {
        #if os(iOS)
        .topBarTrailing
        #else
        .automatic
        #endif
    }
}
