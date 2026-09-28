// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import AuthenticationServices

// TODO: throw custom errors with explanations
/// Globally manage shared, persistent accounts from the SwiftUI environment.
@MainActor
@Observable
public final class AccountManager {
    public private(set) var allAccounts: [Account] = []
    private var store: LocalStore

    /// Feature flag enables autoconfiguring new accounts using [JMAP](https://jmap.io), when supported by email provider.
    public var isJMAPAvailable: Bool = false

    public func account(for id: UUID) -> Account? {
        allAccounts.first(where: { $0.id == id })
    }

    public func set(_ account: Account, at index: Int? = nil) throws {
        let backupAccounts = allAccounts

        defer {
            allAccounts = backupAccounts
        }

        var accounts: [Account] = allAccounts
        let currentIndex: Int? = accounts.firstIndex { account.id == $0.id }
        if let currentIndex {
            accounts.remove(at: currentIndex)
        }
        let index: Int? = index ?? currentIndex  // New index OR current index OR nil (append to end)
        if let index, index < accounts.count {
            accounts.insert(account, at: index)  // Insert at new or current target index
        } else {
            accounts.append(account)  // Append to end of array
        }
        allAccounts = accounts
        try store.saveAccounts(accounts)
        allAccounts = try store.loadAccounts()
    }

    public func delete(_ account: Account) throws {
        account.deleteAuthorization()
        try store.deleteAccount(account.id)
        allAccounts = try store.loadAccounts()
    }

    public func deleteAccounts() throws {
        URLCredentialStorage.shared.deleteAuthorizations()
        try store.deleteAllAccounts()
        allAccounts = []
    }

    public init(store: LocalStore) throws {
        self.store = store
        allAccounts = try store.loadAccounts()
    }

    public func hasLoggedInAccount() -> Bool {
        for account in allAccounts {
            if account.authorization.isExpired == false {
                return true
            }
        }
        return false
    }

    public func checkAndRenewExpirations() async throws {
        var updatedAccounts: [Account] = []
        for account in allAccounts {
            let serverAuth: Authorization = account.authorization
            guard account.incomingServer?.authenticationType == .oAuth2, serverAuth.isExpired else {
                continue
            }
            do {
                var account = account
                account.authorization = try await renewExpiredToken(
                    authConfig: account.authConfig!,
                    refreshToken: serverAuth.refreshToken!,
                    user: serverAuth.user
                )
                updatedAccounts.append(account)
            } catch {
                self.error = .authorization(error)
            }
        }

        for account in updatedAccounts {
            try self.set(account)
        }
    }

    private func renewExpiredToken(authConfig: OAuth2.Configuration, refreshToken: String, user: String, retry attempts: Int = 2) async throws -> Authorization {
        do {
            let tokenRequest: URLRequest = try .refreshToken(
                authConfig,
                refreshToken: refreshToken
            )
            let data: Data = try await URLSession.shared.data(for: tokenRequest).0
            let response: RefreshTokenResponse = try JSONDecoder().decode(RefreshTokenResponse.self, from: data)
            let token: Token = .bearer(
                response.accessToken,
                Date(timeIntervalSinceNow: TimeInterval(response.expiresIn))
            )
            return .oauth(user: user, token: token, refresh: .refresh(refreshToken))
        } catch {
            guard attempts > 0 else {
                throw error  // Retry attempts exhausted, exit
            }
            // Retry request, decrementing remaining attempts
            return try await renewExpiredToken(
                authConfig: authConfig,
                refreshToken: refreshToken,
                user: user,
                retry: attempts - 1
            )
        }
    }
}
