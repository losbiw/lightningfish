// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Account
import Testing
import Foundation

struct AuthorizationTests {
    let testExpirDate = Date(timeIntervalSince1970: 0)
    @Test func user() {
        #expect(Authorization.basic(user: "user@example.com IMAP:E621E1F8", password: "").user == "user@example.com IMAP:E621E1F8")
        #expect(
            Authorization
                .oauth(
                    user: "user@example.com IMAP:E621E1F8",
                    token:
                        .bearer("fmu1-1e911257e86b1f194daa-0-a89faae5c11f", testExpirDate),
                    refresh: .refresh("fakeRefreshToken")
                ).user == "user@example.com IMAP:E621E1F8"
        )
        #expect(Authorization.none.user == "")
    }

    @Test func value() {
        #expect(Authorization.basic(user: "user@example.com", password: "P@$sW0rd!").value == "Basic dXNlckBleGFtcGxlLmNvbTpQQCRzVzByZCE=")
        #expect(
            Authorization
                .oauth(
                    user: "user@example.com IMAP:E621E1F8",
                    token: .bearer("fmu1-1e911257e86b1f194daa-0-a89faae5c11f", testExpirDate),
                    refresh: .refresh("fakeRefreshToken")
                ).value == "Bearer Zm11MS0xZTkxMTI1N2U4NmIxZjE5NGRhYS0wLWE4OWZhYWU1YzExZjowLjA6ZmFrZVJlZnJlc2hUb2tlbg=="
        )
        #expect(Authorization.none.value == "")
    }

    @Test func password() {
        #expect(Authorization.basic(user: "user@example.com", password: "P@$sW0rd!").password == "dXNlckBleGFtcGxlLmNvbTpQQCRzVzByZCE=")
        #expect(
            Authorization
                .oauth(
                    user: "user@example.com",
                    token:
                        .bearer("fmu1-1e911257e86b1f194daa-0-a89faae5c11f", testExpirDate),
                    refresh: .refresh("fakeRefreshToken")
                ).password == "Zm11MS0xZTkxMTI1N2U4NmIxZjE5NGRhYS0wLWE4OWZhYWU1YzExZjowLjA6ZmFrZVJlZnJlc2hUb2tlbg=="
        )
        #expect(Authorization.none.password == "")
    }

    @Test func userInit() {
        #expect(Authorization(user: "user@example.com", password: "dXNlckBleGFtcGxlLmNvbTpQQCRzVzByZCE=") == .basic(user: "user@example.com", password: "P@$sW0rd!"))
        #expect(
            Authorization(user: "user@example.com", password: "Zm11MS0xZTkxMTI1N2U4NmIxZjE5NGRhYS0wLWE4OWZhYWU1YzExZjowLjA6ZmFrZVJlZnJlc2hUb2tlbg==")
                == .oauth(
                    user: "user@example.com",
                    token: .bearer(
                        "fmu1-1e911257e86b1f194daa-0-a89faae5c11f",
                        testExpirDate
                    ),
                    refresh: .refresh("fakeRefreshToken")
                )
        )
    }
}
