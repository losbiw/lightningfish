// StateCoordinator.swift
// Core
//
// Created by Vlad Skorinov on 29/06/2026.
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

    public var selectedAccount: Account? {
        guard let selectedAccountId = preferences.selectedAccountId else {
            return nil
        }

        return accountManager.allAccounts.first(where: { $0.id == selectedAccountId })
    }

    public var selectedMailbox: Mailbox? {
        guard !(mailboxManager?.mailboxes.isEmpty)! else {
            return nil
        }

        if let selectedMailboxName = preferences.selectedMailboxName,
            let mailbox = mailboxManager?.mailboxes.first(where: { $0.name == selectedMailboxName })
        {
            return mailbox
        } else {
            // TODO: replace the predicate with IMAP isInbox() method
            let inbox = mailboxManager?.mailboxes.first(where: { $0.name == "INBOX" })

            return inbox ?? mailboxManager?.mailboxes.first
        }
    }

    public func deleteCurrentAccount() throws {
        guard selectedAccount != nil else { return }

        accountManager.delete(selectedAccount!)
        // TODO: delete messages from the local DB here
    }

    public func loadEmails(cursor: UID? = nil) async throws -> [Email] {
        guard selectedMailbox != nil else {
            throw SessionError.noMailboxExists
        }

        let emails = await mailboxManager!.emails(in: selectedMailbox!, cursor: cursor)

        return emails ?? []
    }

    public init(store: LocalStore, accountManager: AccountManager) throws {
        self.accountManager = accountManager
        self.store = store
        preferences = UserPreferencesManager(store: _store, accounts: accountManager.allAccounts)
    }
}

public enum SessionError: Error {
    case noMailboxExists
}
