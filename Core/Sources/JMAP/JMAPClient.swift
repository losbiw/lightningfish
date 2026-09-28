// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import OSLog

/// Configure `JMAPClient` with a single ``Server``.
public class JMAPClient {

    /// Convenience
    /// - Parameter server: ``Server`` configuration for JMAP service provider
    /// - Returns: `JMAPClient` with an authenticated ``Session`` already started
    public static func session(_ server: Server) async throws -> Self {
        let client: Self = Self(server)
        try await client.session()  // Start session
        return client
    }

    public let server: Server
    public private(set) var session: Session?

    public func thread(for email: Email) async throws -> [Email] {
        if let session {
            guard let id: String = session.accounts.keys.first else {
                throw JMAPError.method(.accountNotFound)
            }
            guard
                let response: MethodGetResponse = try await URLSession.shared.jmapAPI(
                    [
                        Thread.GetMethod(
                            id,
                            ids: [
                                email.threadID
                            ])
                    ], url: session.apiURL, authorization: server.authorization!
                ).first as? MethodGetResponse
            else {
                throw URLError(.cannotDecodeContentData)
            }
            let threads: [JMAP.Thread] = try response.decode([JMAP.Thread].self)
            guard let ids: [String] = threads.first?.emailIDs,
                !ids.isEmpty
            else {
                throw URLError(.cannotDecodeContentData)
            }
            return try await emails(ids)
        } else {
            try await session()
            return try await thread(for: email)
        }
    }

    public func emails(in mailbox: Mailbox) async throws -> [Email] {
        if let session {
            guard let id: String = session.accounts.keys.first else {
                throw JMAPError.method(.accountNotFound)
            }
            guard
                let response: MethodQueryResponse = try await URLSession.shared.jmapAPI(
                    [
                        Email.QueryMethod(id, filter: .inMailbox(mailbox.id))
                    ], url: session.apiURL, authorization: server.authorization!
                ).first as? MethodQueryResponse
            else {
                throw JMAPError.underlying(URLError(.cannotDecodeContentData))
            }
            return try await emails(response.ids)
        } else {
            try await session()
            return try await emails(in: mailbox)
        }
    }

    public func emails(_ ids: [String]) async throws -> [Email] {
        if let session {
            guard let id: String = session.accounts.keys.first else {
                throw JMAPError.method(.accountNotFound)
            }
            guard
                let response: MethodGetResponse = try await URLSession.shared.jmapAPI(
                    [
                        Email.GetMethod(id, ids: ids)
                    ], url: session.apiURL, authorization: server.authorization!
                ).first as? MethodGetResponse
            else {
                throw URLError(.cannotDecodeContentData)
            }
            return try response.decode([Email].self)
        } else {
            try await session()
            return try await emails(ids)
        }
    }

    /// Create a new mailbox.
    @discardableResult public func create(mailbox: Mailbox) async throws -> MethodSetResponse? {
        guard let session, let accountID: String = session.accounts.keys.first else {
            throw JMAPError.method(.accountNotFound)
        }
        logger?.info("Creating \"\(mailbox.name)\" mailbox…")
        return try await URLSession.shared.jmapAPI(
            [
                Mailbox.SetMethod(
                    accountID,
                    actions: [
                        .create([
                            mailbox.id: [
                                "name": mailbox.name,
                                "isSubscribed": mailbox.isSubscribed
                            ]
                        ])
                    ])
            ], url: session.apiURL, authorization: server.authorization!
        ).first as? MethodSetResponse
    }

    /// Update an existing mailbox.
    @discardableResult public func update(mailbox: Mailbox) async throws -> MethodSetResponse? {
        guard let session, let accountID: String = session.accounts.keys.first else {
            throw JMAPError.method(.accountNotFound)
        }
        logger?.info("Updating \"\(mailbox.name)\" mailbox…")
        return try await URLSession.shared.jmapAPI(
            [
                Mailbox.SetMethod(
                    accountID,
                    actions: [
                        .update([
                            mailbox.id: [
                                "name": mailbox.name,
                                "isSubscribed": mailbox.isSubscribed
                            ]
                        ])
                    ])
            ], url: session.apiURL, authorization: server.authorization!
        ).first as? MethodSetResponse
    }

    /// Destroy an existing mailbox.
    @discardableResult public func destroy(mailbox: Mailbox) async throws -> MethodSetResponse? {
        guard let session, let accountID: String = session.accounts.keys.first else {
            throw JMAPError.method(.accountNotFound)
        }
        logger?.info("Destroying \"\(mailbox.name)\" mailbox…")
        return try await URLSession.shared.jmapAPI(
            [
                Mailbox.SetMethod(
                    accountID,
                    actions: [
                        .destroy([
                            mailbox.id
                        ])
                    ])
            ], url: session.apiURL, authorization: server.authorization!
        ).first as? MethodSetResponse
    }

    public func mailboxes() async throws -> [Mailbox] {
        if let session {
            guard let id: String = session.accounts.keys.first else {
                throw JMAPError.method(.accountNotFound)
            }
            guard
                let response: MethodGetResponse = try await URLSession.shared.jmapAPI(
                    [
                        Mailbox.GetMethod(id)
                    ], url: session.apiURL, authorization: server.authorization!
                ).first as? MethodGetResponse
            else {
                throw JMAPError.underlying(URLError(.cannotDecodeContentData))
            }
            return try response.decode([Mailbox].self)
        } else {
            try await session()
            return try await mailboxes()
        }
    }

    @discardableResult public func session() async throws -> Session {
        let session: Session = try await URLSession.shared.jmapSession(server: server)
        self.session = session
        return session
    }

    required public init(
        _ server: Server,
        logger: Logger? = Logger(subsystem: "net.rainfrog", category: "JMAP")
    ) {
        self.server = server
        self.logger = logger
    }

    private let logger: Logger?
}

extension Filter {
    static func inMailbox(_ id: String) -> Self {
        Self([
            Email.Condition.inMailbox(id)
        ])
    }
}
