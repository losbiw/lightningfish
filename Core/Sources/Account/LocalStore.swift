// LocalStore.swift
// Core
//
// Created by Vlad Skorinov on 28/06/2026.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
//

import Foundation
import GRDB
import EmailAddress

/// Basically just interfaces with GRDB, mostly adheres to the spec in `Database.md`
public struct LocalStore {
    private var dbQueue: DatabaseQueue

    public init() throws {
        let defaultDBURL = try FileManager.default
            .url(for: .applicationDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("rainfrog.sqlite")
            .path

        try self.init(dbPath: defaultDBURL)
    }

    public init(dbPath: String) throws {
        let migrator = LocalStoreMigrator()

        dbQueue = try DatabaseQueue(path: dbPath)
        try migrator.applyMigrations(db: dbQueue)
    }

    public func loadPreferences() throws -> UserPreferences? {
        try dbQueue.read { db in
            try UserPreferences.find(db, id: "1")
        }
    }

    public func savePreferences(_ preferences: UserPreferences) throws {
        try dbQueue.write { db in
            try preferences.save(db)
        }
    }

    // public func loadMailbox(_ mailbox: String) -> Mailbox {}
}

// MARK: Account DB methods
extension LocalStore {
    public func loadAccounts() throws -> [Account] {
        try dbQueue.read { db in
            try Account.fetchAll(db)
        }
    }

    public func deleteAccount(_ id: UUID) throws {
        let _ = try dbQueue.write { db in
            try Account.deleteOne(db, id: id)
        }
    }

    public func deleteAllAccounts() throws {
        let _ = try dbQueue.write { db in
            try Account.deleteAll(db)
        }
    }

    public func saveAccounts(_ accounts: [Account]) throws {
        try dbQueue.write { db in
            try accounts.forEach { try $0.save(db) }
        }
    }
}

// MARK: Mailbox DB methods
extension LocalStore {
    public func loadEmails(for mailbox: String, cursor: UID?) throws -> [Email] {
        try dbQueue.read { db in
            var request =
                EmailRecord
                .filter(Column("mailbox") == mailbox)
                .order(Column("received").desc)

            if cursor != nil {
                request = request.filter(Column("uid") < cursor?.rawValue)
            }

            return try EmailRecord.fetchAll(db, request).map { $0.toEmail() }
        }
    }

    public func cacheEmails(in mailbox: String, emails: [Email]) throws {
        try dbQueue.write { db in
            for email in emails {
                let emailRec = EmailRecord(email, mailbox: mailbox)
                try emailRec.save(db)

                if let body = email.body {
                    let bodyRec = EmailBodyRecord(body: body, emailId: email.id, mailbox: mailbox)
                    try bodyRec.save(db)
                }
            }
        }
    }

    /// Loads one cached message, including its body when it has already been fetched.
    public func loadEmailBody(for uid: UID, in mailbox: String) throws -> Email? {
        try dbQueue.read { db in
            let record =
                try EmailRecord
                .filter(Column("mailbox") == mailbox && Column("uid") == uid.rawValue)
                .fetchOne(db)

            guard let record else { return nil }

            let body =
                try EmailBodyRecord
                .filter(Column("mailbox") == mailbox && Column("emailId") == record.id)
                .fetchOne(db)?
                .body

            return record.toEmail(body: body)
        }
    }
}

public struct EmailRecord: Codable, Identifiable, FetchableRecord, PersistableRecord {
    public let mailbox: String
    public let from: [MailAddress]
    public let sender: [MailAddress]
    public let replyTo: [MailAddress]
    public let to: [MailAddress]
    public let bcc: [MailAddress]
    public let cc: [MailAddress]
    public let received: Date?
    public let sent: Date?
    public let messageID: [String]
    public let threadID: [String]
    public let inReplyTo: [String]
    public let subject: String?
    public let blobID: String?
    public let uid: UInt32?
    public let preview: String?
    public let flags: Set<UnifiedFlag>?
    public let id: String

    public init(_ email: Email, mailbox: String) {
        self.from = email.from
        self.sender = email.sender
        self.replyTo = email.replyTo
        self.to = email.to
        self.bcc = email.bcc
        self.cc = email.cc
        self.received = email.received
        self.sent = email.sent
        self.messageID = email.messageID
        self.threadID = email.threadID
        self.inReplyTo = email.inReplyTo
        self.subject = email.subject
        self.blobID = email.blobID
        self.uid = email.uid?.rawValue
        self.preview = email.preview
        self.flags = email.flags
        self.id = email.id
        self.mailbox = mailbox
    }

    public func toEmail(body: EmailBody? = nil) -> Email {
        return Email(self, body: body)
    }
}

public struct EmailBodyRecord: Codable, FetchableRecord, PersistableRecord {
    let mailbox: String
    let emailId: String
    let body: EmailBody

    public init(body: EmailBody, emailId: String, mailbox: String) {
        self.body = body
        self.emailId = emailId
        self.mailbox = mailbox
    }
}

private struct LocalStoreMigrator {
    private var migrator = DatabaseMigrator()

    public init() {
        // Tables mirror the `Codable` records one column per stored property, so GRDB can save and
        // fetch them as-is. Column types are left to SQLite: JSON-encoded values go in as text.
        migrator.registerMigration(
            "Create account table",
            migrate: { db in
                try db.create(table: "account") { t in
                    t.column("id").notNull()
                    t.column("name")
                    t.column("deletePolicy")
                    t.column("identities")
                    t.column("servers")
                    t.column("avatarColor")
                    t.column("authConfig")
                    t.primaryKey(["id"])
                }
            })

        migrator.registerMigration(
            "Create preferences table",
            migrate: { db in
                try db.create(table: "userPreferences") { t in
                    t.column("id").notNull()
                    t.column("selectedAccountId")
                    t.column("selectedMailboxByAccount")
                    t.primaryKey(["id"])
                }
            })

        migrator.registerMigration(
            "Create email cache tables",
            migrate: { db in
                try db.create(table: "emailRecord") { t in
                    t.column("mailbox").notNull()
                    t.column("id").notNull()
                    t.column("from").notNull()
                    t.column("sender").notNull()
                    t.column("replyTo").notNull()
                    t.column("to").notNull()
                    t.column("bcc").notNull()
                    t.column("cc").notNull()
                    t.column("received")
                    t.column("sent")
                    t.column("messageID").notNull()
                    t.column("threadID").notNull()
                    t.column("inReplyTo").notNull()
                    t.column("subject")
                    t.column("blobID")
                    t.column("uid")
                    t.column("preview")
                    t.column("flags")
                    t.primaryKey(["mailbox", "id"])
                }
                try db.create(index: "emailRecord_by_mailbox_uid", on: "emailRecord", columns: ["mailbox", "uid"])

                try db.create(table: "emailBodyRecord") { t in
                    t.column("mailbox").notNull()
                    t.column("emailId").notNull()
                    t.column("body").notNull()
                    t.primaryKey(["mailbox", "emailId"])
                    t.foreignKey(["mailbox", "emailId"], references: "emailRecord", columns: ["mailbox", "id"], onDelete: .cascade)
                }
            })
    }

    public func applyMigrations(db: DatabaseQueue) throws {
        try migrator.migrate(db)
    }
}
