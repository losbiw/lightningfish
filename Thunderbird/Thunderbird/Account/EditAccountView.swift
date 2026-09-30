// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/s

import Account
import SwiftUI

struct EditAccountView: View {
    init(_ account: Account) {
        self.account = account
        self.incomingServer = account.incomingServer?.clone() ?? Server(.imap)
        self.outgoingServer = account.outgoingServer?.clone() ?? Server(.smtp)
    }

    @Environment(AccountManager.self) private var accountManager: AccountManager
    @Environment(\.dismiss) private var dismiss: DismissAction
    @State private var account: Account
    @State private var incomingServer: Server
    @State private var outgoingServer: Server
    @State private var failure: Failure?

    // MARK: View
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Incoming Server")
                    .font(.headline)
                EditServerView($incomingServer, $account)
                Divider()
                Text("Outgoing Server")
                    .font(.headline)
                EditServerView($outgoingServer, $account)

            }
            .padding()
        }
        .navigationTitle("Edit Account")
        .toolbar {
            Button(action: {
                account.servers = [
                    incomingServer,
                    outgoingServer
                ]
                do {
                    try accountManager.set(account)
                    dismiss()
                } catch {
                    failure = Failure(error, title: "Couldn't save the account")
                }
            }) {
                Text("Save")
            }
        }
        .errorAlert($failure)
    }
}

#Preview("Edit Account View") {
    @Previewable @State var store = try! LocalStore()
    @Previewable @State var accountManager = AccountManager(store: store)

    NavigationStack {
        EditAccountView(Account("example@thunderbird.net"))
    }
    .environment(accountManager)
}
