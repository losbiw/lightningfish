// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import Autoconfiguration
import SwiftUI

struct AccountInformation: View {
    init(_ path: Binding<NavigationPath>) {
        _path = path
    }

    @Binding var path: NavigationPath
    @Environment(AccountManager.self) private var accountManager: AccountManager
    @Environment(LoginDetails.self) private var loginDetails: LoginDetails
    @State private var showManual: Bool = true
    @State private var emailAddress: String = ""
    @State private var account: Account?
    @State private var config: ClientConfig?
    @State private var password: String = ""
    @State private var error: Error?
    @State private var loginServer: Server = Server(.imap)
    @State private var loginAuth: Authorization = .none
    @State private var loginAuthConfig: OAuth2.Configuration?

    private func refreshAccount() {
        account = emailAddress.isEmailAddress ? Account(emailAddress, provider: config?.emailProvider) : nil
        guard let account = account else { return }
        guard let incomingServer = account.incomingServer else { return }
        loginServer = incomingServer
        loginAuthConfig = account.authConfig
        loginAuth = account.authorization
    }

    var body: some View {
        Form {
            TextEntryWrapper("account_server_settings_email_address_label", "your.email@example.com", $emailAddress)
                #if os(iOS)
            .keyboardType(.emailAddress)
            .submitLabel(.search)
                #endif
            AutoconfigView($config, for: emailAddress)
                .listRowSeparator(.hidden)
            if config != nil && account != nil {
                Button(
                    action: {
                        loginDetails.inProgressAccount = account
                        loginDetails.enteredEmail = emailAddress
                        path.append("ManualAccountSetup")

                    }) {
                        Text("account_server_edit_configuration")
                            .padding(5.5)
                            .frame(maxWidth: .infinity)
                            .underline()
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .buttonStyle(.plain)
                if account?.incomingServer?.authenticationType != nil {
                    AuthorizationView(
                        $loginAuth,
                        error: $error,
                        for: loginServer.username,
                        authenticationType: loginServer.authenticationType,
                        authConfig: $loginAuthConfig
                    ).onChange(of: loginAuth) {
                        guard var account = account else { return }
                        account.avatarColor = randomizeAvatarColor()
                        var incomingServerInfo = account.incomingServer ?? Server(.imap)
                        var outgoingServerInfo = account.outgoingServer ?? Server(.smtp)
                        incomingServerInfo.username = emailAddress
                        outgoingServerInfo.username = emailAddress
                        account.authorization = loginAuth
                        account.authConfig = loginAuthConfig
                        account.servers = [incomingServerInfo, outgoingServerInfo]

                        do {
                            try accountManager.set(account)
                        } catch {
                            self.error = error
                        }
                    }
                }
            }
            if error != nil || showManual {
                Button(
                    action: {
                        loginDetails.inProgressAccount = nil
                        path.append("EmailAccountTypeSelection")

                    }) {
                        Text("account_server_manual_configuration")
                            .padding(5.5)
                            .frame(maxWidth: .infinity)
                            .underline()

                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .buttonStyle(.plain)
            }
        }
        .onChange(of: emailAddress, initial: true) {
            config = nil
        }
        .onChange(of: config, initial: true) {
            refreshAccount()
        }
        .scrollContentBackground(.hidden)
        #if os(iOS)
        .navigationBarTitleDisplayMode(NavigationBarItem.TitleDisplayMode.inline)
        #endif
        .navigationTitle("account_server_information_title")
    }
}
