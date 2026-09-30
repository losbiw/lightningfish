// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Manage and display a single ``Email`` message for a given ``Account``.
@Observable
public final class EmailManager {
    public let account: Account
    public private(set) var email: Email?

    public init(_ email: Email?, account: Account) {
        self.account = account
        self.email = email
    }

    public func refreshEmail() async throws {
        guard let email else { return }

        switch account.emailProtocol {
        case .imap:
            guard let uid: UID = email.uid else {
                throw IMAPError.capabilityNotSupported("UID")
            }
            let client: IMAPClient = try await account.imapClient
            let message: Message = try await client.fetch(uid: uid)
            self.email = Email(message)
        case .jmap:
            let client: JMAPClient = try await account.jmapClient
            let emails: [JMAP.Email] = try await client.emails([email.id])
            guard !emails.isEmpty else {
                throw JMAPError.method(.invalidResultReference)
            }
            self.email = Email(emails[0])
        }
    }
}
