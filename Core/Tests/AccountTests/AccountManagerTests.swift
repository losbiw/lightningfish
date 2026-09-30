// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Account
import Testing
import Foundation
@MainActor
struct AccountManagerTests {
    @Test func set() throws {
        lock.lock()
        defer { lock.unlock() }
        let store: LocalStore = try LocalStore(dbPath: ":memory:")
        let accounts: AccountManager = AccountManager(store: store)
        try accounts.deleteAccounts()
        let allAccounts: [Account] = [
            Account(name: "Example 1"),
            Account(name: "Example 2"),
            Account(name: "Example 3")
        ]
        for account in allAccounts {
            try accounts.set(account)
        }
        #expect(accounts.allAccounts == allAccounts)
        try accounts.set(Account(name: "Example 2a", id: allAccounts[1].id))
        #expect(accounts.allAccounts == [allAccounts[0], Account(name: "Example 2a", id: allAccounts[1].id), allAccounts[2]])
        #expect(accounts.allAccounts[1].name == "Example 2a")
        try accounts.set(Account(name: "Example 2b", id: allAccounts[1].id), at: 0)
        #expect(accounts.allAccounts == [Account(name: "Example 2b", id: allAccounts[1].id), allAccounts[0], allAccounts[2]])
        #expect(accounts.allAccounts[0].name == "Example 2b")
        try accounts.set(Account(name: "Example 2", id: allAccounts[1].id), at: 0)
        let account: Account = Account(name: "Example 4")
        try accounts.set(account)
        #expect(accounts.allAccounts == [allAccounts[1], allAccounts[0], allAccounts[2], account])
        #expect(accounts.allAccounts.last?.name == "Example 4")
        try accounts.deleteAccounts()
    }

    @Test func delete() throws {
        lock.lock()
        defer { lock.unlock() }
        let store: LocalStore = try LocalStore(dbPath: ":memory:")
        let accounts: AccountManager = AccountManager(store: store)
        try accounts.deleteAccounts()
        let allAccounts: [Account] = [
            Account(name: "Example 1", servers: [Server(.imap), Server(.smtp)]),
            Account(name: "Example 2", servers: [Server(.imap), Server(.smtp)]),
            Account(name: "Example 3", servers: [Server(.imap), Server(.smtp)])
        ]
        for account in allAccounts {
            try accounts.set(account)
        }
        #expect(accounts.allAccounts == allAccounts)
        try accounts.delete(accounts.allAccounts[1])
        #expect(accounts.allAccounts == [allAccounts[0], allAccounts[2]])
        try accounts.deleteAccounts()
    }
}

private let lock: NSLock = NSLock()
