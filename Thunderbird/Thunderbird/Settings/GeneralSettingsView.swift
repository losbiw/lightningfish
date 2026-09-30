// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import SwiftUI

struct GeneralSettingsView: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    @Environment(\.openURL) private var openURL: OpenURLAction
    @State private var failure: Failure?

    var body: some View {
        NavigationStack {
            List {
                Section("General Settings") {

                }
                Section("accounts_heading") {
                    ForEach(accountManager.allAccounts) { account in
                        HStack {
                            Text(account.name)
                            Spacer()
                            Menu {
                                Button(action: {
                                    do {
                                        try accountManager.delete(account)
                                    } catch {
                                        failure = Failure(error, title: "Couldn't remove the account")
                                    }
                                }) {
                                    Text("account_sign_out_button")
                                }
                            } label: {
                                Label("options_button", systemImage: "ellipsis")
                                    .labelStyle(.iconOnly)
                                    .foregroundStyle(.black)
                            }.compositingGroup()

                        }
                    }
                    NavigationLink(destination: {
                        ManualAccount()
                    }) {
                        Label("Add Account", systemImage: "plus")
                    }.navigationLinkIndicatorVisibility(.hidden)
                }
                Section("Miscellaneous") {
                    NavigationLink("Feature Flags", destination: FeatureFlagDebugView())
                    Button(
                        "donation_support",
                        action: {
                            guard let url = URL(string: "https://www.thunderbird.net/en-US/donate/") else { return }
                            openURL(url)
                        })
                }
            }
        }
        .navigationTitle("settings_header")
        .errorAlert($failure)
    }
}
