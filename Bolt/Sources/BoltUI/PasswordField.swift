// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

public struct PasswordField: View {
    let titleKey: LocalizedStringKey

    public init(_ titleKey: LocalizedStringKey = "Password", text: Binding<String>, isSecure: Bool = true) {
        self.titleKey = titleKey
        self.isSecure = isSecure
        _text = text
    }

    @Binding private var text: String
    @State private var isSecure: Bool

    // MARK: View
    public var body: some View {
        HStack(spacing: 10.0) {
            ZStack(alignment: .trailing) {
                SecureField(titleKey, text: $text)
                    .monospaced()
                    .opacity(isSecure ? 1.0 : 0.0)
                TextField(titleKey, text: $text)
                    .autoFormattingDisabled()
                    .monospaced()
                    .opacity(isSecure ? 0.0 : 1.0)
            }
            Button(action: {
                isSecure.toggle()
            }) {
                Image(systemName: isSecure ? "eye.slash" : "eye.fill")
            }
        }
    }
}

#Preview("Password Field") {
    @Previewable @State var text: String = "correct horse battery staple"

    PasswordField(text: $text)
        .onChange(of: text, initial: true) {
            print(text)
        }
        .padding()
}
