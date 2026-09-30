// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A mailbox address, or a named RFC 5322 / JMAP address group.
///
/// Groups don't nest: RFC 5322 group members are mailboxes, and JMAP groups are homogenous address
/// lists, so a group holds plain ``EmailAddress`` values rather than more groups.
public enum MailAddress: Hashable, Sendable, Codable {
    case address(EmailAddress)
    case group(label: String?, addresses: [EmailAddress])

    /// Every mailbox address in this value, ignoring grouping.
    public var addresses: [EmailAddress] {
        switch self {
        case .address(let address):
            [address]
        case .group(_, let addresses):
            addresses
        }
    }

    /// A concise label suitable for message-list UI.
    public var displayName: String {
        switch self {
        case .address(let address):
            address.label ?? address.value
        case .group(let label, let addresses):
            label ?? addresses.first.map { $0.label ?? $0.value } ?? ""
        }
    }
}

/// Shared email address model suitable for IMAP, JMAP and SMTP
public struct EmailAddress: CustomStringConvertible, ExpressibleByStringLiteral, Hashable, Identifiable, Sendable, Codable {
    public let value: String
    public let label: String?

    public var host: String? {
        URL(string: "http://\(value.components(separatedBy: "@").last!)")?.host()
    }

    public var local: String? {
        value.contains("@") ? value.components(separatedBy: "@").dropLast().joined(separator: "@") : nil
    }

    public var isEmailAddress: Bool { !(host ?? "").isEmpty && !(local ?? "").isEmpty }

    public init(_ value: String, label: String? = nil) {
        let components: [String] = value.trimmed().components(separatedBy: "<")
        if components.count == 2, components[1].hasSuffix(">") {  // "Example Name <name@example.com>"
            self.value = "\(components[1].dropLast())"
            self.label = label ?? components[0].trimmed()
        } else {
            let label: String = label?.trimmed() ?? ""
            self.value = components[0].trimmed()
            self.label = !label.isEmpty ? label : nil
        }
    }

    // MARK: CustomStringConvertible
    public var description: String { !(label ?? "").isEmpty ? "\(label!) <\(value)>" : value }

    // MARK: ExpressibleByStringLiteral
    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }

    // MARK: Identifiable
    public var id: String { value }
}
