// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import SwiftUI

struct ContentView: View {
    @Environment(SessionManager.self) private var session: SessionManager
    @Environment(AccountManager.self) private var accountManager: AccountManager

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
                await accountManager.checkAndRenewExpirations()
            }
            .error()
        }
    }
}

#Preview("Content View") {
    @Previewable @State var store = try! LocalStore()
    @Previewable @State var accountManager = AccountManager(store: store)
    @Previewable @State var session = try! SessionManager(store: store, accountManager: accountManager)

    ContentView()
        .environment(session)
        .environment(accountManager)
}
