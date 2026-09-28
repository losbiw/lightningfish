// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Core
import SwiftUI

extension View {
    func error() -> some View {
        modifier(ErrorView())
    }
}

struct ErrorView: ViewModifier {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    @State private var isPresented: Bool = false

    private var message: String {
        guard let error: Error = accountManager.error else {
            return "An unknown error occurred"
        }
        return "\(error)"
    }

    // MARK: ViewModifier
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $isPresented, actions: {}) {
                Text(message)
            }
            .onChange(of: accountManager.error, initial: true) {
                isPresented = accountManager.error != nil
            }
            .onChange(of: isPresented) {
                guard accountManager.error != nil, !isPresented else { return }
                accountManager.error = nil
            }
    }
}
