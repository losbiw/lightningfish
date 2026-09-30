// StateCoordinator.swift
// Core
//
// Created by Vlad Skorinov on 29.06.2026.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
//

import Foundation

@Observable
public final class SessionManager {
    private var store: LocalStore
    private var accountManager: AccountManager
    private var preferences: UserPreferencesManager
    private var mailboxManager: MailboxManager?

    @MainActor
    public var selectedAccount: Account? {
        guard let selectedAccountId = preferences.selectedAccountId else {
            return nil
        }

        return accountManager.allAccounts.first(where: { $0.id == selectedAccountId })
    }

    public var selectedMailbox: Mailbox? {
        guard let mailboxManager, !(mailboxManager.mailboxes.isEmpty) else {
            return nil
        }

        if let selectedMailboxName = preferences.selectedMailboxName,
            let mailbox = mailboxManager.mailboxes.first(where: { $0.name == selectedMailboxName })
        {
            return mailbox
        } else {
            // TODO: replace the predicate with IMAP isInbox() method
            let inbox = mailboxManager.mailboxes.first(where: { $0.name == "INBOX" })

            return inbox ?? mailboxManager.mailboxes.first
        }
    }

    @MainActor
    public init(store: LocalStore, accountManager: AccountManager) {
        self.accountManager = accountManager
        self.store = store
        preferences = UserPreferencesManager(store: store, accounts: accountManager.allAccounts)
    }

    /// Loads persisted session state; call once when the app starts.
    @MainActor
    public func load() throws {
        try preferences.load()
        
        guard let selectedAccount else {
            return
        }
        
        mailboxManager = MailboxManager(account: selectedAccount, store: store)
    }

    @MainActor
    public func deleteCurrentAccount() throws {
        guard let selectedAccount else { return }

        try accountManager.delete(selectedAccount)
        mailboxManager = nil  // the deleted account's mailboxes went with it
        // TODO: delete messages from the local DB here
    }

    public func loadEmails(cursor: UID? = nil) async throws -> [Email] {
        guard let mailboxManager, let selectedMailbox else {
            throw AccountError.session(.noMailboxExists)
        }

        return try await mailboxManager.emails(in: selectedMailbox, cursor: cursor)
    }
}

public enum SessionError: Error, CustomStringConvertible {
    case noMailboxExists

    // MARK: CustomStringConvertible
    public var description: String {
        switch self {
        case .noMailboxExists: "No mailbox exists"
        }
    }
}
