// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import SwiftUI

@main
struct App: SwiftUI.App {
    @State private var store: LocalStore
    @State private var accountManager: AccountManager
    @State private var session: SessionManager
    @State private var showAlert = false
    @State private var featureFlags: FeatureFlags = FeatureFlags(distribution: .current)

    init() {
        let store = try! LocalStore()
        let accountManager = AccountManager(store: store)
        session = try! SessionManager(store: store, accountManager: accountManager)

        self.store = store
        self.accountManager = accountManager
    }

    // MARK: App
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(accountManager)
                    .environment(session)
                    .environment(featureFlags)
                if showAlert {
                    FeatureNotImplementedView()
                }
            }
        }.onChange(of: AlertManager.shared.showAlert) {
            showAlert = AlertManager.shared.showAlert
        }
        #if os(macOS)
        .defaultSize(width: 768.0, height: 512.0)
        .windowResizability(.contentMinSize)
        .windowStyle(.hiddenTitleBar)
        #endif
    }
}
