// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Account
import Testing
import Foundation

struct AccountTests {
    @Test func incomingServer() {
        #expect(Account(name: "user@example.com", servers: [.imap, .smtp]).incomingServer?.serverProtocol == .imap)
        #expect(Account(name: "user@example.com", servers: [.jmap]).incomingServer?.serverProtocol == .jmap)
        #expect(Account(name: "user@example.com", servers: [.smtp]).incomingServer == nil)
    }

    @Test func outgoingServer() {
        #expect(Account(name: "user@example.com", servers: [.imap, .smtp]).outgoingServer?.serverProtocol == .smtp)
        #expect(Account(name: "user@example.com", servers: [.jmap]).outgoingServer?.serverProtocol == .jmap)
        #expect(Account(name: "user@example.com", servers: [.imap]).outgoingServer == nil)
    }

    @Test func server() {
        #expect(Account(name: "user@example.com", servers: [.imap, .smtp]).server(.imap)?.serverProtocol == .imap)
        #expect(Account(name: "user@example.com", servers: [.imap, .smtp]).server(.smtp)?.serverProtocol == .smtp)
        #expect(Account(name: "user@example.com", servers: [.imap, .smtp]).server(.jmap) == nil)
        #expect(Account(name: "user@example.com", servers: [.jmap]).server(.jmap)?.serverProtocol == .jmap)
        #expect(Account(name: "user@example.com", servers: [.jmap]).server(.imap) == nil)
    }
}

extension AccountTests {
    @Test func autoconfig() async throws {
        var account: Account = try await .autoconfig("example@fastmail.com", isJMAPAvailable: true)
        #expect(account.incomingServer?.serverProtocol == .jmap)
        #expect(account.incomingServer?.hostname == "api.fastmail.com")
        #expect(account.incomingServer?.port == 443)
        #expect(account.outgoingServer?.serverProtocol == .jmap)
        #expect(account.outgoingServer?.hostname == "api.fastmail.com")
        #expect(account.outgoingServer?.port == 443)
        account = try await .autoconfig("example@fastmail.com")
        #expect(account.incomingServer?.serverProtocol == .imap)
        #expect(account.incomingServer?.hostname == "imap.fastmail.com")
        #expect(account.incomingServer?.port == 993)
        #expect(account.outgoingServer?.serverProtocol == .smtp)
        #expect(account.outgoingServer?.hostname == "smtp.fastmail.com")
        #expect(account.outgoingServer?.port == 465)
    }
}

extension AccountTests {
    @Test func imapClient() async throws {
        await #expect(throws: IMAPError.self) {
            let _ = try await Account.imap.imapClient
        }
    }

    @Test func jmapClient() async throws {
        await #expect(throws: URLError.self) {
            let _ = try await Account.jmap.jmapClient
        }
    }
}

extension AccountTests {
    @Test(.enabled(if: isKeychainAvailable)) func authorization() async throws {
        URLCredentialStorage.shared.deleteAuthorizations()
        var account: Account = try await .autoconfig("example@fastmail.com", isJMAPAvailable: true)
        #expect(account.authorization == .none)
        account.authorization =
            .oauth(
                user: " ",
                token: .bearer("zemhu8-omdRiz-zisbov", Date(timeIntervalSince1970: 0.0)),
                refresh: .refresh("fakeRefreshToken")
            )
        #expect(account.authorization.user == "example@fastmail.com")
        #expect(account.authorization.password == "emVtaHU4LW9tZFJpei16aXNib3Y6MC4wOmZha2VSZWZyZXNoVG9rZW4=")
        switch account.authorization {
        case .oauth(let user, let token, let refresh):
            #expect(user == "example@fastmail.com")
            #expect(token.value == "zemhu8-omdRiz-zisbov")
            #expect(refresh.value == "fakeRefreshToken")
        default:
            throw URLError(.redirectToNonExistentLocation)
        }
        account.authorization = .basic(user: " ", password: "P@$$w0rd!")
        #expect(account.authorization.user == "example@fastmail.com")
        #expect(account.authorization.password == "ZXhhbXBsZUBmYXN0bWFpbC5jb206UEAkJHcwcmQh")
        switch account.authorization {
        case .basic(let user, let password):
            #expect(user == "example@fastmail.com")
            #expect(password == "P@$$w0rd!")
        default:
            throw URLError(.redirectToNonExistentLocation)
        }
        account.authorization = .none
        #expect(account.authorization == .none)
        #expect(URLCredentialStorage.shared.authorization(for: account.emailAddress!.value) == nil)
    }
}

private extension Account {
    static var imap: Self {
        Self(
            name: "",
            identities: [
                "example@thunderbird.net"
            ],
            servers: [
                .gmail,
                Server(.smtp)
            ])
    }

    static var jmap: Self {
        Self(
            name: "",
            identities: [
                "example@fastmail.com"
            ],
            servers: [
                .fastmail
            ])
    }
}

private extension Server {
    static var imap: Self {
        Self(
            .imap,
            connectionSecurity: .none,
            authenticationType: .none,
            username: "user",
            hostname: "imap.example.com"
        )
    }

    static var jmap: Self {
        Self(
            .jmap,
            connectionSecurity: .none,
            authenticationType: .none,
            username: "user",
            hostname: "jmap.example.com"
        )
    }

    static var smtp: Self {
        Self(
            .smtp,
            connectionSecurity: .none,
            authenticationType: .none,
            username: "user",
            hostname: "smtp.example.com"
        )
    }
}
