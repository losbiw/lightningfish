// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Manage and display mailboxes for a given ``Account``.
@Observable
public final class MailboxManager {
    public let account: Account
    private let store: LocalStore
    public private(set) var mailboxes: [Mailbox] = []
    public private(set) var emails: [String: [Email]] = [:]
    public let folderManager: FolderManager

    public init(account: Account, store: LocalStore) {
        self.account = account
        self.store = store
        self.folderManager = FolderManager(account: account)
    }

    public func mailbox(_ name: String) -> Mailbox? {
        mailboxes.first(where: { $0.name == name })
    }

    public func mailbox(for id: String) -> Mailbox? {
        mailboxes.first(where: { $0.id == id })
    }

    public func emailWithBody(for uid: UID, in mailbox: Mailbox) async throws -> Email? {
        if let cached = try store.loadEmailBody(for: uid, in: mailbox.name), cached.body != nil {
            return cached
        }

        switch account.emailProtocol {
        case .imap:
            let client: IMAPClient = try await account.imapClient
            try await client.select(mailbox: IMAP.Mailbox.Name(mailbox.name))
            let message: Message = try await client.fetch(uid: uid)  // fetches the entire body by default
            let email = Email(message)
            try store.cacheEmails(in: mailbox.name, emails: [email])
            return email
        case .jmap:
            return nil
        }
    }

    private func mergeEmails(_ cached: [Email], _ new: [Email]) -> [Email] {
        return Array(Set(cached + new)).sorted().reversed()
    }

    public func emails(in mailbox: Mailbox, cursor: UID?) async throws -> [Email] {
        let cache: [Email] = try store.loadEmails(for: mailbox.name, cursor: cursor)

        let serverEmails: [Email] = try await {
            switch self.account.emailProtocol {
            case .imap:
                let client: IMAPClient = try await self.account.imapClient
                try await client.select(mailbox: IMAP.Mailbox.Name(mailbox.name))
                let messages: MessageSet = try await client.fetch()
                return messages.keys.sorted().reversed().map { Email(messages[$0]!) }
            case .jmap:
                let client: JMAPClient = try await self.account.jmapClient
                let emails: [JMAP.Email] = try await client.emails(in: JMAP.Mailbox(name: mailbox.name, id: mailbox.id))
                return emails.map { Email($0) }
            }
        }()

        let mergedEmails = mergeEmails(cache, serverEmails)

        try store.cacheEmails(in: mailbox.name, emails: mergedEmails)

        return mergedEmails
    }

    public func createMailbox(_ name: String) async throws {
        switch account.emailProtocol {
        case .imap:
            let client: IMAPClient = try await account.imapClient
            try await client.create(mailbox: IMAP.Mailbox.Name(name))
            mailboxes.append(Mailbox(name))
        case .jmap:
            let client: JMAPClient = try await account.jmapClient
            try await client.create(mailbox: JMAP.Mailbox(name: name))
        }

        try await refreshMailboxes()
    }

    public func rename(_ mailbox: Mailbox, to name: String) async throws {
        switch account.emailProtocol {
        case .imap:
            let client: IMAPClient = try await account.imapClient
            try await client.rename(mailbox: IMAP.Mailbox.Name(mailbox.name), to: IMAP.Mailbox.Name(name))
        case .jmap:
            let client: JMAPClient = try await account.jmapClient
            try await client.update(mailbox: JMAP.Mailbox(name: name, isSubscribed: mailbox.isSubscribed, id: mailbox.id))
        }

        try await refreshMailboxes()
    }

    public func delete(_ mailbox: Mailbox) async throws {
        switch account.emailProtocol {
        case .imap:
            let client: IMAPClient = try await account.imapClient
            try await client.delete(mailbox: IMAP.Mailbox.Name(mailbox.name))
        case .jmap:
            let client: JMAPClient = try await account.jmapClient
            try await client.destroy(mailbox: JMAP.Mailbox(name: mailbox.name, id: mailbox.id))
        }

        try await refreshMailboxes()
    }

    public func subscribe(_ mailbox: Mailbox) async throws {
        switch account.emailProtocol {
        case .imap:
            let client: IMAPClient = try await account.imapClient
            try await client.subscribe(mailbox: IMAP.Mailbox.Name(mailbox.name))
        case .jmap:
            let client: JMAPClient = try await account.jmapClient
            try await client.update(mailbox: JMAP.Mailbox(name: mailbox.name, isSubscribed: true, id: mailbox.id))
        }

        try await refreshMailboxes()
    }

    public func unsubscribe(_ mailbox: Mailbox) async throws {
        switch account.emailProtocol {
        case .imap:
            let client: IMAPClient = try await account.imapClient
            try await client.unsubscribe(mailbox: IMAP.Mailbox.Name(mailbox.name))
        case .jmap:
            let client: JMAPClient = try await account.jmapClient
            try await client.update(mailbox: JMAP.Mailbox(name: mailbox.name, isSubscribed: false, id: mailbox.id))
        }

        try await refreshMailboxes()
    }

    public func refreshMailboxes() async throws {
        switch account.emailProtocol {
        case .imap:
            let client: IMAPClient = try await account.imapClient
            let mailboxes: [(IMAP.Mailbox, IMAP.Mailbox.Status?)] = try await client.list()
            self.mailboxes = mailboxes.map { Mailbox($0, id: self.mailbox($0.0.path.name.description)?.id) }  // Transfer UUIDs from previous list
        case .jmap:
            let client: JMAPClient = try await account.jmapClient
            let mailboxes: [JMAP.Mailbox] = try await client.mailboxes()
            self.mailboxes = mailboxes.map { Mailbox($0) }
        }

        await folderManager.refreshFolders(mailboxes: mailboxes)
    }
}
