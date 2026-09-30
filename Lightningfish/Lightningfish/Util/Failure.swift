// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import SwiftUI

/// A failure to show the user: what went wrong, and what we were doing when it did.
struct Failure {
    let title: LocalizedStringKey
    let error: AccountError

    init(_ error: Error, title: LocalizedStringKey) {
        self.title = title
        self.error = AccountError(error)
    }

    var message: String {
        guard let description = error.errorDescription else {
            return "An unknown error occurred."
        }
        guard let suggestion = error.recoverySuggestion else {
            return description
        }
        return "\(description)\n\n\(suggestion)"
    }
}

extension View {
    /// Presents a screen-owned failure as an alert, clearing it when dismissed.
    func errorAlert(_ failure: Binding<Failure?>) -> some View {
        alert(
            failure.wrappedValue?.title ?? "",
            isPresented: Binding(
                get: { failure.wrappedValue != nil },
                set: { if !$0 { failure.wrappedValue = nil } }
            ),
            presenting: failure.wrappedValue
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { failure in
            Text(failure.message)
        }
    }
}
