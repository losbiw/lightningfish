// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Account
import Testing
import Foundation

struct URLCredentialStorageTests {
    @Test(.enabled(if: isKeychainAvailable)) func authorization() {
        let space: URLProtectionSpace = URLProtectionSpace(host: "com.example")
        let authorization: Authorization = .basic(user: "user@netscape.net", password: "essmI1-vudwic-wwanar")
        URLCredentialStorage.shared.deleteAuthorizations(space: space)
        #expect(URLCredentialStorage.shared.authorization(for: authorization.user, space: space) == nil)
        URLCredentialStorage.shared.set(authorization: authorization, space: space)
        #expect(URLCredentialStorage.shared.authorization(for: authorization.user, space: space) == authorization)
        URLCredentialStorage.shared.deleteAuthorizations(space: space)
        #expect(URLCredentialStorage.shared.credentials(for: space) == nil)
    }

    @Test(.enabled(if: isKeychainAvailable)) func setAuthorization() {
        let space: URLProtectionSpace = URLProtectionSpace(host: "org.example")
        URLCredentialStorage.shared.deleteAuthorizations(space: space)
        #expect(URLCredentialStorage.shared.credentials(for: space) == nil)
        URLCredentialStorage.shared.set(authorization: .basic(user: "user.name@gmail.com", password: "12345678"), space: space)
        #expect(URLCredentialStorage.shared.authorization(for: "user.name@gmail.com", space: space)?.password == "dXNlci5uYW1lQGdtYWlsLmNvbToxMjM0NTY3OA==")
        URLCredentialStorage.shared
            .set(
                authorization:
                    .oauth(
                        user: "user.name@gmail.com",
                        token: .bearer("zemhu8-omdRiz-zisbov", Date(timeIntervalSince1970: 0.0)),
                        refresh: .refresh("zemhu8-omdRiz-zisbov-refresh")
                    ),
                space: space
            )  // Duplicate user
        #expect(URLCredentialStorage.shared.credentials(for: space)?.count == 1)  // One credential stored per user
        #expect(URLCredentialStorage.shared.authorization(for: "user.name@gmail.com", space: space)?.password == "emVtaHU4LW9tZFJpei16aXNib3Y6MC4wOnplbWh1OC1vbWRSaXotemlzYm92LXJlZnJlc2g=")
        URLCredentialStorage.shared.deleteAuthorization(for: "user.name@gmail.com", space: space)
        #expect(URLCredentialStorage.shared.credentials(for: space) == nil)
    }

    @Test(.enabled(if: isKeychainAvailable)) func deleteAuthorication() {
        let space: URLProtectionSpace = URLProtectionSpace(host: "net.example")
        URLCredentialStorage.shared.deleteAuthorizations(space: space)
        #expect(URLCredentialStorage.shared.credentials(for: space) == nil)
        URLCredentialStorage.shared
            .set(
                authorization: .basic(user: "example@netscape.net", password: "correct horse battery staple"),
                persistence: .permanent,
                space: space
            )
        URLCredentialStorage.shared
            .set(
                authorization: .basic(user: "user@icloud.com", password: "abcd1234"),
                persistence: .forSession,
                space: space
            )
        URLCredentialStorage.shared
            .set(
                authorization: .basic(user: "user@icloud.com", password: "abcd1234"),
                persistence: .permanent,
                space: space
            )  // Duplicate credential
        URLCredentialStorage.shared
            .set(
                authorization:
                    .oauth(
                        user: "user@example.com",
                        token: .bearer("gAAAAUTHtoKENb3arerJWe", Date()),
                        refresh: .refresh("fakerefreshtokens")
                    ),
                persistence: .forSession,
                space: space
            )
        #expect(URLCredentialStorage.shared.credentials(for: space)?.count == 3)  // Credentials are equatable and de-duplicated by by `username`
        URLCredentialStorage.shared.deleteAuthorization(for: "user@icloud.com", space: space)
        #expect(URLCredentialStorage.shared.credentials(for: space)?.count == 2)
        URLCredentialStorage.shared.deleteAuthorization(for: "example@netscape.net", space: space)
        #expect(URLCredentialStorage.shared.credentials(for: space)?.count == 1)
        URLCredentialStorage.shared.deleteAuthorization(for: "user@example.com", space: space)
        #expect(URLCredentialStorage.shared.credentials(for: space) == nil)
    }

    @Test(.enabled(if: isKeychainAvailable)) func deleteAuthorizations() {
        let space: URLProtectionSpace = URLProtectionSpace(host: "biz.example")
        URLCredentialStorage.shared.deleteAuthorizations(space: space)
        #expect(URLCredentialStorage.shared.credentials(for: space) == nil)
        URLCredentialStorage.shared
            .set(
                authorization: .basic(user: "user@netscape.net", password: "correct horse battery staple"),
                persistence: .permanent,
                space: space
            )
        URLCredentialStorage.shared
            .set(
                authorization: .basic(user: "username@icloud.com", password: "abcd1234"),
                persistence: .forSession,
                space: space
            )
        URLCredentialStorage.shared
            .set(
                authorization: .basic(user: "username@icloud.com", password: "abcd1234"),
                persistence: .permanent,
                space: space
            )  // Duplicate credential
        URLCredentialStorage.shared
            .set(
                authorization:
                    .oauth(
                        user: "admin@example.com",
                        token: .bearer("gAAAAUTHtoKENb3arerJWe", Date()),
                        refresh: .refresh("fakerefreshtokens")
                    ),
                persistence: .forSession,
                space: space
            )
        #expect(URLCredentialStorage.shared.credentials(for: space)?.count == 3)  // Credentials are equatable and de-duplicated by by `username`
        URLCredentialStorage.shared.deleteAuthorizations(space: space)
        #expect(URLCredentialStorage.shared.credentials(for: space) == nil)
    }
}

var isKeychainAvailable: Bool {
    #if os(macOS)
    true  // Keychain only available (to non-hosted tests) on macOS
    #else
    false
    #endif
}
