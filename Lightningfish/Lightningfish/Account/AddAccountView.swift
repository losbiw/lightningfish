// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import Autoconfiguration
import SwiftUI

struct AddAccountView: View {
    init(_ emailAddress: String = "") {
        self.emailAddress = emailAddress
    }

    @Environment(AccountManager.self) private var accountManager: AccountManager
    @Environment(\.dismiss) private var dismiss: DismissAction
    @State private var showManual: Bool = false
    @State private var emailAddress: String
    @State private var account: Account?
    @State private var config: ClientConfig?
    @State private var failure: Failure?

    private func refreshAccount() {
        account = emailAddress.isEmailAddress ? Account(emailAddress, provider: config?.emailProvider) : nil
    }

    // MARK: View
    var body: some View {
        ScrollView {
            VStack(spacing: 17.0) {
                TextField(text: $emailAddress) {
                    Text("Email Address")
                }
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                #if os(iOS)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .submitLabel(.search)
                #endif

                // Portable autoconfig widget/view
                AutoconfigView($config, for: emailAddress)
            }
            .padding()
        }
        .navigationTitle("Add Account")
        .onChange(of: emailAddress, initial: true) {
            refreshAccount()
        }
        .onChange(of: config, initial: true) {
            refreshAccount()
        }
        .toolbar {
            Button(action: {
                guard let account else { return }
                do {
                    try accountManager.set(account)
                    dismiss()
                } catch {
                    failure = Failure(error, title: "Couldn't save the account")
                }
            }) {
                Text("Save")
            }
            .disabled(account == nil)
        }
        .errorAlert($failure)
    }
}

#Preview("Add Account View") {
    let store = try! LocalStore()
    let accountManager: AccountManager = AccountManager(store: store)

    AddAccountView()
        .environment(accountManager)
}
