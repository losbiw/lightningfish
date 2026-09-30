// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Account
import MIME
import Testing
import Foundation

struct LocalStoreTests {
    @Test func emailBodyRoundTrip() throws {
        let store: LocalStore = try LocalStore(dbPath: ":memory:")
        let uid: UID = UID(rawValue: 42)
        let body: EmailBody = EmailBody(
            html: "<p>Hello</p>",
            text: "Hello",
            attachments: [
                EmailAttachment(
                    data: Data([0x01, 0x02, 0x03]),
                    contentType: .application("pdf"),
                    contentDisposition: .attachment(.init(filename: "file.pdf")),
                    contentID: "attachment-1"
                )
            ],
            preview: "Hello"
        )
        let email: Email = Email(
            from: [.address(EmailAddress("sender@example.com", label: "Sender"))],
            to: [.group(label: "Team", addresses: [EmailAddress("a@example.com"), EmailAddress("b@example.com")])],
            received: Date(timeIntervalSince1970: 1_700_000_000),
            subject: "Hello",
            body: body,
            flags: [.seen, .keyword("NonJunk")],
            uid: uid,
            preview: "Hello",
            id: "message-1"
        )

        try store.cacheEmails(in: "INBOX", emails: [email])

        let cached: Email? = try store.loadEmailBody(for: uid, in: "INBOX")
        #expect(cached?.subject == "Hello")
        #expect(cached?.id == "message-1")
        #expect(cached?.from == [.address(EmailAddress("sender@example.com", label: "Sender"))])
        #expect(cached?.to == [.group(label: "Team", addresses: [EmailAddress("a@example.com"), EmailAddress("b@example.com")])])
        #expect(cached?.flags == [.seen, .keyword("NonJunk")])
        #expect(cached?.body?.text == "Hello")
        #expect(cached?.body?.html(.none) == "<p>Hello</p>")
        #expect(cached?.body?.preview == "Hello")
        #expect(cached?.body?.attachments.count == 1)
        #expect(cached?.body?.attachments.first?.data == Data([0x01, 0x02, 0x03]))
        #expect(cached?.body?.attachments.first?.contentType == .application("pdf"))
        #expect(cached?.body?.attachments.first?.contentDisposition == .attachment(.init(filename: "file.pdf")))
        #expect(cached?.body?.attachments.first?.contentID == "attachment-1")
    }

    @Test func savingTwiceUpdatesRatherThanDuplicates() throws {
        let store: LocalStore = try LocalStore(dbPath: ":memory:")
        let uid: UID = UID(rawValue: 7)
        let email: Email = Email(subject: "First", flags: [], uid: uid, id: "message-2")

        try store.cacheEmails(in: "INBOX", emails: [email])
        try store.cacheEmails(in: "INBOX", emails: [email, Email(subject: "Second", flags: [], uid: UID(rawValue: 8), id: "message-3")])

        let emails: [Email] = try store.loadEmails(for: "INBOX", cursor: nil)
        #expect(emails.count == 2)
        #expect(Set(emails.compactMap(\.subject)) == ["First", "Second"])
    }
}
