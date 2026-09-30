// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import BoltUI
import SwiftUI

struct ManualAccount: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    @Environment(\.dismiss) private var dismiss: DismissAction
    @State private var loginDetails: LoginDetails = LoginDetails()
    @State private var path: NavigationPath = NavigationPath()

    // MARK: View
    var body: some View {
        NavigationStack(path: $path) {
            AccountInformation($path)
                .environment(loginDetails)
                .environment(accountManager)
                .toolbarRole(.editor)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        CloseButton("close_button")
                    }
                }
                .onChange(of: accountManager.allAccounts.count) {
                    dismiss()
                }
                .navigationBarBackButtonHidden()
                .navigationDestination(for: String.self) { destination in
                    if destination == "EmailAccountTypeSelection" {
                        EmailAccountTypeSelection($path).toolbarRole(.editor).environment(loginDetails)
                    }
                    if destination == "ManualAccountSetup" {
                        if loginDetails.inProgressAccount == nil {
                            ManualServerSetup(loginDetails)
                                .toolbarRole(.editor)
                                .environment(accountManager)
                                .environment(loginDetails)
                        } else {
                            ManualServerSetup(loginDetails)
                                .toolbarRole(.editor)
                                .environment(accountManager)
                                .environment(loginDetails)
                        }
                    }
                }
        }.accentColor(.gray)
    }
}

#Preview("Manual Account Setup") {
    @Previewable @State var getStarted: Bool = false
    @Previewable @State var store = try! LocalStore()
    @Previewable @State var accountManager = AccountManager(store: store)

    ManualAccount()
        .environment(accountManager)
        .sheet(isPresented: $getStarted) {
            EmptyView()
                .presentationDragIndicator(.visible)
        }
}

@Observable
class LoginDetails {
    var inProgressAccount: Account?
    var enteredEmail: String
    var serverProtocol: ServerProtocol?

    init(inProgressAccount: Account? = nil, enteredEmail: String = "", serverProtocol: ServerProtocol? = nil) {
        self.inProgressAccount = inProgressAccount
        self.enteredEmail = enteredEmail
        self.serverProtocol = serverProtocol
    }
}
