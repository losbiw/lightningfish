// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import SwiftUI

struct ContentView: View {
    @Environment(SessionManager.self) private var session: SessionManager
    @Environment(AccountManager.self) private var accountManager: AccountManager
    @State private var failure: Failure?

    @State private var isSetupShown: Bool = false

    // MARK: View
    var body: some View {
        if accountManager.allAccounts.isEmpty {
            WelcomeScreen($isSetupShown)
                .sheet(isPresented: $isSetupShown) {
                    ManualAccount()
                        .presentationDragIndicator(.visible)
                }
        } else {
            NavigationStack {
                EmailListView()
            }
            .task {
                isSetupShown = false
                do {
                    try await accountManager.checkAndRenewExpirations()
                } catch {
                    failure = Failure(error, title: "Couldn't refresh your sign-ins")
                }
            }
            .errorAlert($failure)
        }
    }
}

#Preview("Content View") {
    let store = try! LocalStore()
    let accountManager = AccountManager(store: store)
    let session = SessionManager(store: store, accountManager: accountManager)

    ContentView()
        .environment(session)
        .environment(accountManager)
}
