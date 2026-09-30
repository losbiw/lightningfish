// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import EmailAddress
import Foundation

/// One element of a JMAP `address-list`, which is either a single address or a named group of addresses.
/// See [RFC 8621, Section 4.1.2.4](https://jmap.io/spec/rfc8621/#section-4.1.2.4-7).
///
/// This mirrors JMAP's *wire* shape — `{"email": …, "name": …}` for one address and
/// `{"addresses": […], "name": …}` for a group — and converts to the shared ``MailAddress`` model,
/// which keeps its own shape for storage.
struct AddressListElement: Decodable {
    let email: String?
    let name: String?
    let addresses: [AddressListElement]?

    /// Converts this wire element to a ``MailAddress``.
    var mailAddress: MailAddress {
        guard let addresses else {
            return .address(EmailAddress(email ?? "", label: name))
        }

        // JMAP groups are homogenous address lists; nested groups are flattened.
        return .group(label: name, addresses: addresses.flatMap { $0.mailAddress.addresses })
    }

    // MARK: Decodable
    init(from decoder: any Decoder) throws {
        // Older payloads stored an address as a plain string, e.g. "Example <name@example.com>".
        if let container = try? decoder.singleValueContainer(), let string = try? container.decode(String.self) {
            email = string
            name = nil
            addresses = nil
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        addresses = try container.decodeIfPresent([AddressListElement].self, forKey: .addresses)
    }

    private enum CodingKeys: String, CodingKey {
        case email, name, addresses
    }
}
