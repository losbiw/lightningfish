// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import SwiftUI

struct AccountsView: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    @State private var failure: Failure?

    // MARK: View
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 17.0) {
                    // List all accounts
                    ForEach(accountManager.allAccounts) { account in
                        HStack {
                            // Delete account
                            Button(action: {
                                do {
                                    try accountManager.delete(account)
                                } catch {
                                    failure = Failure(error, title: "Couldn't remove the account")
                                }
                            }) {
                                Image(systemName: "trash")
                            }
                            .foregroundStyle(.red)

                            // Edit account
                            NavigationLink(destination: {
                                EditAccountView(account)
                            }) {
                                HStack {
                                    Text(account.name)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Accounts")
            .toolbar {
                ToolbarItem(placement: .addAccount) {
                    // Add account
                    NavigationLink(destination: {
                        AddAccountView()
                    }) {
                        Label("Add Account", systemImage: "plus")
                    }
                }
            }
        }
        .errorAlert($failure)
    }
}

#Preview("Accounts View") {
    let store = try! LocalStore()
    let accountManager: AccountManager = AccountManager(store: store)

    NavigationStack {
        AccountsView()
    }
    .environment(accountManager)
}

private extension ToolbarItemPlacement {
    static var addAccount: Self {
        #if os(iOS)
        .bottomBar
        #else
        .automatic
        #endif
    }
}
