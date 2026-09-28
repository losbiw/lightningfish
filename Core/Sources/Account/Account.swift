// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@_exported import Autoconfiguration
@_exported import EmailAddress
@_exported import IMAP
@_exported import JMAP
@_exported import MIME
@_exported import SMTP
import Foundation
import GRDB

public struct Account: Codable, Equatable, Hashable, Identifiable, FetchableRecord, PersistableRecord {
    public enum EmailProtocol: String, CaseIterable, CustomStringConvertible, Identifiable {
        case imap = "IMAP/SMTP"
        case jmap = "JMAP"

        // MARK: CustomStringConvertible
        public var description: String { rawValue }

        // MARK: Identifiable
        public var id: String { rawValue }
    }

    public var name: String
    public var deletePolicy: DeletePolicy
    public var identities: [EmailAddress]
    public var servers: [Server]
    public var avatarColor: String
    public var authConfig: OAuth2.Configuration?

    public var incomingServer: Server? { server(.jmap) ?? server(.imap) ?? nil }
    public var outgoingServer: Server? { server(.jmap) ?? server(.smtp) ?? nil }
    public var emailAddress: EmailAddress? { identities.first }

    /// Store account credentials locally in the [Apple keychain.](https://developer.apple.com/documentation/security/storing-keys-in-the-keychain)
    public var authorization: Authorization {
        set {
            guard let user: String = emailAddress?.value, !user.isEmpty else { return }
            URLCredentialStorage.shared.deleteAuthorization(for: user)
            guard !newValue.password.isEmpty else { return }
            URLCredentialStorage.shared.set(authorization: Authorization(user: user, password: newValue.password), persistence: .permanent)
        }
        get {
            guard let user: String = emailAddress?.value, !user.isEmpty,
                let authorization: Authorization = URLCredentialStorage.shared.authorization(for: user)
            else {
                return .none
            }
            return Authorization(user: user, password: authorization.password)
        }
    }

    public func deleteAuthorization() {
        guard let user: String = emailAddress?.value, !user.isEmpty else { return }
        URLCredentialStorage.shared.deleteAuthorization(for: user)
    }

    public var emailProtocol: EmailProtocol {
        servers.map { $0.serverProtocol }.contains(.jmap) ? .jmap : .imap
    }

    public func server(_ serverProtocol: ServerProtocol) -> Server? {
        servers.first(where: { $0.serverProtocol == serverProtocol })
    }

    /// Configure an `Account` using ``Autoconfiguration.EmailProvider``.
    public init(_ emailAddress: String, provider: EmailProvider? = nil) {
        self.init(EmailAddress(emailAddress), provider: provider)
    }

    /// Configure an `Account` using ``Autoconfiguration.EmailProvider``.
    public init(_ emailAddress: EmailAddress, provider: EmailProvider? = nil) {
        self.init(
            name: emailAddress.value,
            identities: [
                emailAddress
            ],
            servers: (provider?.servers ?? []).compactMap { Server($0) }
        )
    }

    /// Configure an `Account` using memberwise initializer.
    public init(
        name: String,
        deletePolicy: DeletePolicy = .never,
        identities: [EmailAddress] = [],
        servers: [Server] = [],
        id: UUID = UUID(),
        avatar: String = "user-blue",
    ) {
        self.name = name
        self.deletePolicy = deletePolicy
        self.identities = identities
        self.servers = servers
        self.id = id
        self.avatarColor = avatar
    }

    // MARK: Identifiable
    public let id: UUID
}

extension Account {

    /// Autoconfigure a new `Account`.
    public static func autoconfig(_ emailAddress: String, isJMAPAvailable: Bool = false) async throws -> Self {
        do {
            // TODO: un-hardcode fastmail from this. Just need to figure out where the JMAP-compatible hosts would be stored
            if isJMAPAvailable, try emailAddress.host == "fastmail.com" {
                return Account(
                    name: emailAddress,
                    identities: [
                        EmailAddress(emailAddress)
                    ],
                    servers: [
                        Server(
                            .jmap,
                            connectionSecurity: .tls,
                            authenticationType: .password,
                            username: emailAddress,
                            // TODO: un-hardcode here too
                            hostname: "api.fastmail.com"
                        )
                    ]
                )
            } else {
                let config: ClientConfig = try await URLSession.shared.autoconfig(emailAddress).config
                return Account(emailAddress, provider: config.emailProvider)
            }
        } catch {
            throw AccountError.autoconfig(error)
        }
    }
}

extension Account {
    var imapClient: IMAPClient {
        get async throws {
            if let client: IMAPClient = Self.clients[id] as? IMAPClient {
                // IMAP Client already exists for account ID; reconnect and return
                if !client.isConnected {
                    try await client.connect()
                    try await client.login()
                }
                return client
            } else {
                // No client exists for account ID; make a new one, connect and return
                guard let incomingServer else {
                    throw IMAPError.serverProtocolMismatch
                }
                let client: IMAPClient = IMAPClient(try IMAP.Server(incomingServer, authorization: authorization))
                try await client.connect()
                try await client.login()
                Self.clients[id] = client  // Donate to shared pool
                return client
            }
        }
    }

    var jmapClient: JMAPClient {
        get async throws {
            if let client: JMAPClient = Self.clients[id] as? JMAPClient, client.session != nil {
                // JMAP Client already exists for account ID; return
                return client
            } else {
                // No client exists for account ID; start a new session and return
                guard let server: Server = servers.first else {
                    throw JMAPError.serverProtocolMismatch
                }
                let client: JMAPClient = try await .session(try JMAP.Server(server, authorization: authorization))
                guard client.session != nil else {
                    throw JMAPError.sessionNotFound
                }
                return client
            }
        }
    }

    // Share existing IMAP and JMAP clients associated with account
    nonisolated(unsafe) private static var clients: [UUID: Any] = [:]
}
