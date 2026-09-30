// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Account
import Testing
import Foundation

struct EmailTests {
    @Test func gmailMessageID() {
        #expect(Email(IMAP.Message.aol).gmailMessageID == nil)
        #expect(Email(JMAP.Email.fastmail).gmailMessageID == nil)
        #expect(Email(IMAP.Message.gmail).gmailMessageID == 1_865_707_498_850_970_206)
    }

    @Test func gmailThreadID() {
        #expect(Email(IMAP.Message.aol).gmailThreadID == nil)
        #expect(Email(JMAP.Email.fastmail).gmailThreadID == nil)
        #expect(Email(IMAP.Message.gmail).gmailThreadID == 8_509_702_061_865_707_498)
    }

    @Test func imapMessageInit() {
        let aol: Email = Email(IMAP.Message.aol)
        #expect(
            aol.messageID == [
                "<4addb7e5-9bfa-48f6-833a-b7cd846064dc@example.com>"
            ])
        #expect(aol.subject == "Email activity on account")
        #expect(aol.sent == Date(timeIntervalSince1970: 1779277275.0))
        #expect(aol.received == Date(timeIntervalSince1970: 1779277306.0))
        #expect(aol.from.first?.addresses.first == "from@aol.com")
        #expect(aol.from.count == 1)
        #expect(aol.sender.first?.addresses.first == "sender@aol.com")
        #expect(aol.sender.count == 1)
        #expect(aol.replyTo.first?.addresses.first == "reply@aol.com")
        #expect(aol.replyTo.count == 1)
        #expect(aol.to.first?.addresses.first == "Example <example@aol.com>")
        #expect(aol.to.count == 1)
        #expect(aol.cc.isEmpty)
        #expect(aol.bcc.isEmpty)
        #expect(
            aol.threadID == [
                "1598"
            ])
        #expect(aol.id == "AAYqCTjUMm7xS26Ui3FBV9j4skS")

        let gmail: Email = Email(IMAP.Message.gmail)
        #expect(
            gmail.messageID == [
                "<fd838b6b-4245-406c-91b5-21f5d359135d@example.com>",
                "1865707498850970206"
            ])
        #expect(gmail.subject == "Summer Sale Ends Tomorrow!")
        #expect(gmail.sent == Date(timeIntervalSince1970: 1781993898.0))
        #expect(gmail.received == Date(timeIntervalSince1970: 1781993898.0))
        #expect(gmail.from.first?.addresses.first == "Mailing List <list@example.com>")
        #expect(gmail.from.count == 1)
        #expect(gmail.sender.isEmpty)
        #expect(gmail.cc.first?.addresses.first == "copied@gmail.com")
        #expect(gmail.cc.last?.addresses.last == "cc@example.com")
        #expect(gmail.cc.count == 2)
        #expect(
            gmail.threadID == [
                "8509702061865707498"
            ])
        #expect(gmail.id == "1865707498850970206")
    }

    @Test func jmapEmailInit() {
        let fastmail: Email = Email(JMAP.Email.fastmail)
        #expect(
            fastmail.messageID == [
                "9d937078-84ec-4999-b346-9c4218a14a82@mtasv.net"
            ])
        #expect(fastmail.subject == "Your receipt from Fastmail")
        #expect(fastmail.sent == Date(timeIntervalSince1970: 1772226074.0))
        #expect(fastmail.received == Date(timeIntervalSince1970: 1772226076.0))
        #expect(fastmail.sender.isEmpty)
        #expect(fastmail.from.first?.addresses.first == "Fastmail <help@fastmail.com>")
        #expect(fastmail.from.count == 1)
        #expect(fastmail.replyTo.isEmpty)
        #expect(fastmail.to.first?.addresses.first == "example@fastmail.com")
        #expect(fastmail.to.count == 1)
        #expect(fastmail.cc.isEmpty)
        #expect(fastmail.bcc.isEmpty)
        #expect(
            fastmail.threadID == [
                "A-2QEdnnTnWc"
            ])
        #expect(fastmail.id == "StqU8lS8UWc7")
    }
}

private extension IMAP.Message {
    static var aol: Self {
        Self(
            body: nil,
            emailID: "AAYqCTjUMm7xS26Ui3FBV9j4skS",
            envelope: Envelope(
                subject: "Email activity on account",
                date: InternetMessageDate(Date(timeIntervalSince1970: 1779277275.0)),
                from: [
                    .address(EmailAddress("from@aol.com"))
                ],
                sender: [
                    .address(EmailAddress("sender@aol.com"))
                ],
                reply: [
                    .address(EmailAddress("reply@aol.com"))
                ],
                to: [
                    .address(EmailAddress("example@aol.com", label: "Example"))
                ],
                cc: [],
                bcc: [],
                inReplyTo: nil,
                messageID: "<4addb7e5-9bfa-48f6-833a-b7cd846064dc@example.com>"
            ),
            flags: [],
            gmailLabels: [],
            gmailMessageID: nil,
            gmailThreadID: nil,
            internalDate: Date(timeIntervalSince1970: 1779277306.0),
            threadID: "1598",
            uid: 100307
        )
    }

    static var gmail: Self {
        Self(
            body: nil,
            emailID: nil,
            envelope: Envelope(
                subject: "Summer Sale Ends Tomorrow!",
                date: InternetMessageDate(Date(timeIntervalSince1970: 1781993898.0)),
                from: [
                    .address(EmailAddress("list@example.com", label: "Mailing List"))
                ],
                sender: [],
                reply: [
                    .address(EmailAddress("reply@example.com"))
                ],
                to: [
                    .address(EmailAddress("example@gmail.com", label: "Example"))
                ],
                cc: [
                    .address(EmailAddress("copied@gmail.com")),
                    .address(EmailAddress("cc@example.com"))
                ],
                bcc: [],
                inReplyTo: nil,
                messageID: "<fd838b6b-4245-406c-91b5-21f5d359135d@example.com>"
            ),
            flags: [],
            gmailLabels: [],
            gmailMessageID: 1_865_707_498_850_970_206,
            gmailThreadID: 8_509_702_061_865_707_498,
            internalDate: Date(timeIntervalSince1970: 1781993898.0),
            threadID: nil,
            uid: 2963
        )
    }
}

private extension JMAP.Email {
    static var fastmail: Self {
        Self(
            blobID: "G91c5164637b7c508b0bd862634b91b883f5e2970",
            threadID: "A-2QEdnnTnWc",
            mailboxIDs: ["J-T": true],
            keywords: [
                "$maskedemail": true,
                "$x-me-annot-2": true,
                "$hasattachment": true,
                "$istrusted": true
            ],
            size: 117230,
            receivedAt: Date(timeIntervalSince1970: 1772226076.0),
            sentAt: Date(timeIntervalSince1970: 1772226074.0),
            messageID: [
                "9d937078-84ec-4999-b346-9c4218a14a82@mtasv.net"
            ],
            inReplyTo: nil,
            references: nil,
            sender: nil,
            from: [
                .address(EmailAddress("help@fastmail.com", label: "Fastmail"))
            ],
            replyTo: nil,
            to: [
                .address(EmailAddress("example@fastmail.com"))
            ],
            cc: nil,
            bcc: nil,
            subject: "Your receipt from Fastmail",
            bodyStructure: nil,
            textBody: [],
            htmlBody: [],
            attachments: [],
            hasAttachment: false,
            preview: "Thank you for your purchase! Your full invoice is attached to this email.",
            id: "StqU8lS8UWc7"
        )
    }
}
