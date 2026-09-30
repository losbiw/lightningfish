// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import SwiftUI

@main
struct App: SwiftUI.App {
    @State private var accountManager: AccountManager
    @State private var session: SessionManager
    @State private var showAlert = false
    @State private var featureFlags: FeatureFlags = FeatureFlags(distribution: .current)
    @State private var failure: Failure?

    init() {
        let store: LocalStore
        var failure: Failure?

        do {
            store = try LocalStore()
        } catch {
            // Without the on-disk database the app can still run, and report why nothing is stored.
            store = try! LocalStore(dbPath: ":memory:")
            failure = Failure(error, title: "Local storage is unavailable")
        }

        let accountManager = AccountManager(store: store)

        do {
            try accountManager.loadAccounts()
        } catch {
            failure = failure ?? Failure(error, title: "Couldn't load your accounts")
        }

        // The session picks its default account from the loaded accounts, so it must come after them.
        let session = SessionManager(store: store, accountManager: accountManager)

        do {
            try session.load()
        } catch {
            failure = failure ?? Failure(error, title: "Couldn't restore your preferences")
        }

        self.accountManager = accountManager
        self.session = session
        self.failure = failure
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
            .errorAlert($failure)
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
