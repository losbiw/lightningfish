// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Bolt
import SwiftUI

struct TextEntryWrapper: View {

    /// - Parameters:
    ///  - header: The name attached to the entry box
    ///  - suggestionText: The placeholder value for the entry box to give context to the entry field
    ///  - entryText: Binding string to pass data outside wrapper
    init(
        _ header: LocalizedStringKey = "",
        _ suggestion: String = "",
        _ entryText: Binding<String> = .constant(""),
    ) {
        headerText = header
        suggestionText = suggestion
        _entryText = entryText
    }

    private var headerText: LocalizedStringKey
    private var suggestionText: String
    @Binding private var entryText: String

    // MARK: View
    var body: some View {
        TextField(suggestionText, text: $entryText)
            .formInput(headerText)
            .autoFormattingDisabled()
            .focusable()
    }
}
