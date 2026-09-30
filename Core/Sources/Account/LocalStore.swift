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
                var emailRec = EmailRecord(email, mailbox: mailbox)
                try emailRec.save(db)

                if let body = email.body {
                    var bodyRec = EmailBodyRecord(body: body, emailId: email.id, mailbox: mailbox)
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
                .including(optional: EmailRecord.bodyAssociation)
                .filter(Column("mailbox") == mailbox && Column("uid") == uid.rawValue)
                .fetchOne(db)

            return record?.toEmail(body: record?.body?.body)
        }
    }
}

public struct EmailRecord: Codable, Equatable, Hashable, Identifiable, FetchableRecord, PersistableRecord {
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
    public let uid: UID?
    public let preview: String?
    public let flags: Set<Flag>?
    public let id: String

    var body: EmailBodyRecord?
    static let bodyAssociation = hasOne(EmailBodyRecord.self)

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
        self.uid = email.uid
        self.preview = email.preview
        self.flags = email.flags
        self.id = email.id
        self.mailbox = mailbox
    }

    public func toEmail(body: Body? = nil) -> Email {
        return Email(self, body: body)
    }
}

public struct EmailBodyRecord: Codable, FetchableRecord, PersistableRecord {
    let mailbox: String
    let emailId: String
    let body: Body

    static let email = belongsTo(EmailRecord.self)

    public init(body: Body, emailId: String, mailbox: String) {
        self.body = body
        self.emailId = emailId
        self.mailbox = mailbox
    }
}

private struct LocalStoreMigrator {
    private var migrator = DatabaseMigrator()

    public init() {
        migrator.registerMigration(
            "Initialize Rainfrog DB",
            migrate: { db in
                try db.create(table: "session") { t in
                    t.autoIncrementedPrimaryKey("id")
                }
            })

        migrator.registerMigration(
            "Add email cache",
            migrate: { db in
                try db.create(table: "emails") { t in
                    t.column("mailbox", .text).notNull()
                    t.column("emailID", .text).notNull()
                    t.column("uid", .integer)
                    t.column("from", .blob).notNull()
                    t.column("sender", .blob).notNull()
                    t.column("replyTo", .blob).notNull()
                    t.column("to", .blob).notNull()
                    t.column("bcc", .blob).notNull()
                    t.column("cc", .blob).notNull()
                    t.column("received", .datetime)
                    t.column("sent", .datetime)
                    t.column("messageID", .blob).notNull()
                    t.column("threadID", .blob).notNull()
                    t.column("inReplyTo", .blob).notNull()
                    t.column("subject", .text)
                    t.column("blobID", .text)
                    t.column("preview", .text)
                    t.column("flags", .blob).notNull()
                    t.primaryKey(["mailbox", "emailID"])
                }
                try db.create(index: "emails_by_mailbox_uid", on: "emails", columns: ["mailbox", "uid"])

                try db.create(table: "emailBodies") { t in
                    t.column("mailbox", .text).notNull()
                    t.column("emailID", .text).notNull()
                    t.column("body", .blob).notNull()
                    t.primaryKey(["mailbox", "emailID"])
                    t.foreignKey(["mailbox", "emailID"], references: "emails", columns: ["mailbox", "emailID"], onDelete: .cascade)
                }
            })
    }

    public func applyMigrations(db: DatabaseQueue) throws {
        try migrator.migrate(db)
    }
}
