// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import EmailAddress
import Foundation
@testable import JMAP
import Testing

struct EmailAddressTests {

    @Test func decoderInit() throws {
        let emailAddresses: [MailAddress] = try JSONDecoder()
            .decode([AddressListElement].self, from: data)
            .map(\.mailAddress)

        #expect(emailAddresses.count == 5)
        #expect(emailAddresses[0] == .group(label: "Named Group", addresses: [
            EmailAddress("name@example.com", label: "Named Example"),
            EmailAddress("noname@example.com")
        ]))
        #expect(emailAddresses[1] == .address(EmailAddress("emptyname@example.com")))
        #expect(emailAddresses[2] == .address(EmailAddress("nullname@example.com")))
        #expect(emailAddresses[3] == .group(label: nil, addresses: [
            EmailAddress("noname@example.com")
        ]))
        #expect(emailAddresses[4] == .address(EmailAddress("name@example.com", label: "Named Example")))
    }

    @Test func decoderInitFromString() throws {
        // Addresses stored as plain strings by an older version still decode.
        let string: Data = "\"Named Example <name@example.com>\"".data(using: .utf8)!
        let emailAddress: MailAddress = try JSONDecoder().decode(AddressListElement.self, from: string).mailAddress
        #expect(emailAddress == .address(EmailAddress("name@example.com", label: "Named Example")))
    }
}

// swift-format-ignore
private let data: Data = """
[
    {
        "addresses": [
            {
                "email": "name@example.com",
                "name": "Named Example"
            },
            {
                "email": "noname@example.com"
            }
        ],
        "name": "Named Group"
    },
    {
        "email": "emptyname@example.com",
        "name": ""
    },
    {
        "email": "nullname@example.com",
        "name": null
    },
    {
        "addresses": [
            {
                "email": "noname@example.com"
            }
        ]
    },
    {
        "email": "name@example.com",
        "name": "Named Example"
    }
]
""".data(using: .utf8)!
