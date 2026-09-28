// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import EmailAddress
import Foundation
import IMAP
import JMAP
import MIME
import GRDB

/// Common `Email` model represents and losslessly converts to and from both ``IMAP.Message`` and ``JMAP.Email``
public struct Email: CustomStringConvertible, Identifiable, Sendable {
    public var from: [EmailAddressProtocol]
    public var sender: [EmailAddressProtocol]
    public var replyTo: [EmailAddressProtocol]
    public var to: [EmailAddressProtocol]
    public var bcc: [EmailAddressProtocol]
    public var cc: [EmailAddressProtocol]
    public let received: Date?  // IMAP internal message date
    public let sent: Date?  // IMAP envelope date
    public let messageID: [String]
    public let threadID: [String]
    public let inReplyTo: [String]
    public var subject: String?
    public var body: EmailBody?
    public let blobID: String?
    public let uid: UID?
    public let preview: String?
    // TODO: unify flags for IMAP + JMAP
    public let flags: Set<UnifiedFlag>

    public init(
        from: [MailAddress] = [],
        sender: [MailAddress] = [],
        replyTo: [MailAddress] = [],
        to: [MailAddress] = [],
        bcc: [MailAddress] = [],
        cc: [MailAddress] = [],
        received: Date? = nil,
        sent: Date? = nil,
        messageID: [String] = [],
        threadID: [String] = [],
        inReplyTo: [String] = [],
        subject: String? = nil,
        body: EmailBody? = nil,
        blobID: String? = nil,
        flags: Set<Flag>,
        uid: UID? = nil,
        preview: String? = nil,
        id: String? = nil
    ) {
        self.from = from
        self.sender = sender
        self.replyTo = replyTo
        self.to = to
        self.bcc = bcc
        self.cc = cc
        self.received = received
        self.sent = sent
        self.messageID = messageID
        self.threadID = threadID
        self.inReplyTo = inReplyTo
        self.subject = subject
        self.body = body
        self.blobID = blobID
        self.flags = flags
        self.uid = uid
        self.preview = preview
        self.id = id ?? UUID().uuidString(1)
    }

    // MARK: CustomStringConvertible
    public var description: String { messageID.first ?? id }

    // MARK: Identifiable
    public let id: String  // IMAP message ID
}

extension Email {
    public init(_ record: EmailRecord, body: Body?) {
        self.from = record.from
        self.sender = record.sender
        self.replyTo = record.replyTo
        self.to = record.to
        self.bcc = record.bcc
        self.cc = record.cc
        self.received = record.received
        self.sent = record.sent
        self.messageID = record.messageID
        self.threadID = record.threadID
        self.inReplyTo = record.inReplyTo
        self.subject = record.subject
        self.blobID = record.blobID
        self.body = body
        self.flags = record.flags
        self.uid = record.uid
        self.preview = record.preview
        self.id = record.id
    }
}

// UI-related properties
extension Email {
    public var unread: Bool { flags.contains(.seen) }
}

extension Email {
    // Decode Gmail message ID, if present
    var gmailMessageID: UInt64? {
        guard let id: UInt64 = UInt64(messageID.last ?? ""), id > .gmailIDFloor else {
            return nil
        }
        return id
    }

    // Decode Gmail thread ID, if present
    var gmailThreadID: UInt64? {
        guard let id: UInt64 = UInt64(threadID.last ?? ""), id > .gmailIDFloor else {
            return nil
        }
        return id
    }

    // Map from IMAP message
    init(_ message: IMAP.Message) {
        self.init(
            from: message.envelope.from,
            sender: message.envelope.sender,
            replyTo: message.envelope.reply,
            to: message.envelope.to,
            bcc: message.envelope.bcc,
            cc: message.envelope.cc,
            received: message.internalDate,  // IMAP internal message date
            sent: message.envelope.date?.date,  // IMAP envelope date; forget sender time zone
            messageID: message.messageIDs,
            threadID: message.threadIDs,
            inReplyTo: message.inReplyTo,
            subject: message.envelope.subject,
            body: try? EmailBody(body: message.body),
            flags: message.flags,
            uid: message.uid,
            preview: message.preview,
            id: message.emailID ?? message.gmailID
        )
    }

    // Map from JMAP email
    init(_ email: JMAP.Email) {
        self.init(
            from: email.from ?? [],
            sender: email.sender ?? [],
            replyTo: email.replyTo ?? [],
            to: email.to ?? [],
            bcc: email.bcc ?? [],
            cc: email.cc ?? [],
            received: email.receivedAt,
            sent: email.sentAt,
            messageID: email.messageID ?? [],
            threadID: [email.threadID],
            inReplyTo: email.inReplyTo ?? [],
            subject: email.subject,
            body: try? EmailBody(email: email),
            blobID: email.blobID,
            // FIXME: replace the flags placeholder
            flags: Set(),
            uid: UID(rawValue: UInt32(1)),
            preview: email.preview,
            id: email.id
        )
    }
}

// MARK: - EmailAddressProtocol array conversion methods
extension Email {
    // A convenience function that converts an array of `EmailAddressProtocol` to an array of strings.
    public func addressesStringArray(_ a: [EmailAddressProtocol]) -> [String] {
        a.flatMap { $0.addresses.map { $0.value } }
    }

    // A convenience function that combines all of the addresses into a single comma separated string.
    public func commaSeparatedAddresses(_ a: [EmailAddressProtocol]) -> String {
        a.flatMap { $0.addresses.map { $0.value } }.joined(separator: ", ")
    }

    public var toStringArray: [String] { addressesStringArray(to) }
    public var replyToStringArray: [String] { addressesStringArray(replyTo) }
    public var ccStringArray: [String] { addressesStringArray(cc) }
    public var bccStringArray: [String] { addressesStringArray(bcc) }
}

// MARK: - Convenience methods for reassigning senders/receivers
extension Email {
    public func asReply(all: Bool) -> Email {
        var newEmail = self
        newEmail.to = from

        if !all {
            newEmail.cc = []
            newEmail.bcc = []
        }

        return newEmail
    }
}

extension IMAP.Message {

    // Use `gmailMessageID` as ID string, if present
    var gmailID: String? { gmailMessageID != nil ? "\(gmailMessageID!)" : nil }

    // Collect available message IDs, plain and/or Gmail flavored
    var messageIDs: [String] {
        var ids: [String] = []
        if let id: String = envelope.messageID {
            ids.append(id)
        }
        if let id: UInt64 = gmailMessageID {
            ids.append("\(id)")
        }
        return ids
    }

    // Collect available thread IDs, plain and/or Gmail flavored
    var threadIDs: [String] {
        var ids: [String] = []
        if let id: String = threadID {
            ids.append(id)
        }
        if let id: UInt64 = gmailThreadID {
            ids.append("\(id)")
        }
        return ids
    }

    var inReplyTo: [String] {
        var ids: [String] = []
        if let id: String = envelope.inReplyTo {
            ids.append(id)
        }
        return ids
    }

    // Map back to IMAP message
    init(_ email: Email) {
        self.init(
            body: nil,  // email.body,
            emailID: email.id,
            envelope: Envelope(
                subject: email.subject,
                date: email.sent?.internetMessageDate,
                from: email.from,
                sender: email.sender,
                reply: email.replyTo,
                to: email.to,
                cc: email.cc,
                bcc: email.bcc,
                inReplyTo: email.inReplyTo.first,
                messageID: email.messageID.first
            ),
            flags: [],
            gmailLabels: [],
            gmailMessageID: email.gmailMessageID,
            gmailThreadID: email.gmailThreadID,
            internalDate: email.received,
            threadID: email.threadID.first,
            uid: email.uid
        )
    }
}

extension JMAP.Email {

    // Map back to JMAP email
    init(_ email: Email) {
        self.init(
            blobID: email.blobID ?? "",
            threadID: email.threadID.first ?? "",
            mailboxIDs: [:],  // TODO: JMAP mailbox IDs not carried
            keywords: [:],  // TODO: JMAP keywords not implemented
            size: 0,
            receivedAt: email.received,
            sentAt: email.sent,
            messageID: !email.messageID.isEmpty ? email.messageID : nil,
            inReplyTo: !email.inReplyTo.isEmpty ? email.inReplyTo : nil,
            references: nil,
            sender: !email.sender.isEmpty ? email.sender : nil,
            from: !email.from.isEmpty ? email.from : nil,
            replyTo: !email.replyTo.isEmpty ? email.replyTo : nil,
            to: !email.to.isEmpty ? email.to : nil,
            cc: !email.cc.isEmpty ? email.cc : nil,
            bcc: !email.bcc.isEmpty ? email.bcc : nil,
            subject: email.subject,
            bodyStructure: nil,  // TODO: JMAP body structure encoding not implemented
            textBody: [],
            htmlBody: [],
            attachments: [],  // TODO: JMAP attachments not implemented
            hasAttachment: false,
            preview: nil,  // // TODO: JMAP preview not implemented
            id: email.id
        )
    }
}

extension Date {
    var internetMessageDate: InternetMessageDate { InternetMessageDate(self) }
}

private extension UInt64 {
    static let gmailIDFloor: Self = 1_000_000_000_000
}

// lossless conversion to a unified model from IMAP flags/JMAP keywords

public enum UnifiedFlag: Hashable, Sendable, Codable {
    case seen
    case answered
    case flagged
    case draft
    case deleted
    case keyword(String)
}

private extension Flag {
    func normalize(rawFlag: String) -> String {
        if rawFlag.starts(with: "\\") {
            return String(rawFlag.dropFirst(2))
        }

        return rawFlag
    }

    init(flag: UnifiedFlag) {
        switch flag {
        case .seen:
            self = .seen
        case .answered:
            self = .answered
        case .flagged:
            self = .flagged
        case .deleted:
            self = .deleted
        case .draft:
            self = .draft
        case .keyword(let value):
            self = Self.init(normalize(rawFlag: value))
        }
    }
}

private extension JMAP.Email.Keyword {
    func normalize(rawFlag: String) -> String {
        if rawFlag.starts(with: "$") {
            return String(rawFlag.dropFirst())
        }

        return rawFlag
    }

    init(flag: UnifiedFlag) {
        switch flag {
        case .seen:
            self = .seen
        case .answered:
            self = .answered
        case .flagged:
            self = .flagged
        case .deleted:
            self = .deleted
        case .draft:
            self = .draft
        case .keyword(let value):
            self = Flag.extension(value)
        }
    }
}

private extension UnifiedFlag {
    func toIMAP(rawFlag: String) -> String {
        if rawFlag.starts(with: "\\") {
            return String(rawFlag.dropFirst(2))
        }

        return rawFlag
    }

    func to(rawFlag: String) -> String {
        if rawFlag.starts(with: "\\") {
            return String(rawFlag.dropFirst(2))
        }

        return rawFlag
    }

    init(imapFlag: Flag) {
        switch imapFlag {
        case .seen:
            self = .seen
        case .answered:
            self = .answered
        case .flagged:
            self = .flagged
        case .deleted:
            self = .deleted
        case .draft:
            self = .draft
        default:
            // custom IMAP flags start with a backslash so we drop it
            self = .keyword(String(imapFlag).dropFirst())
        }
    }
}
