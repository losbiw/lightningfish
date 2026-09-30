// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import IMAP

/// A message flag, unified across IMAP flags and JMAP keywords.
///
/// The five standard IMAP system flags get their own cases. Everything else — Gmail attributes like
/// `\Important`, IMAP keywords like `NonJunk`, JMAP keywords like `$junk` — is kept verbatim in
/// ``keyword(_:)``, so its spelling survives a round trip through the model.
public enum UnifiedFlag: Hashable, Sendable, Codable {
    case seen
    case answered
    case flagged
    case draft
    case deleted
    case keyword(String)
}

// MARK: - IMAP
extension UnifiedFlag {
    /// IMAP flags compare case-insensitively, so `\SEEN` and `\Seen` map to the same case.
    public init(imap flag: Flag) {
        switch flag {
        case .seen: self = .seen
        case .answered: self = .answered
        case .flagged: self = .flagged
        case .draft: self = .draft
        case .deleted: self = .deleted
        default: self = .keyword(flag.description)  // e.g. `\Important`, `\Recent`, `NonJunk`
        }
    }

    public var imapFlag: Flag {
        switch self {
        case .seen: .seen
        case .answered: .answered
        case .flagged: .flagged
        case .draft: .draft
        case .deleted: .deleted
        case .keyword(let keyword): Flag(keyword)
        }
    }
}

// MARK: - JMAP
extension UnifiedFlag {
    /// JMAP carries keywords as a `[String: Bool]` map, where `true` means the keyword is set.
    public init(jmapKeyword: String) {
        switch jmapKeyword {
        case "$seen": self = .seen
        case "$answered": self = .answered
        case "$flagged": self = .flagged
        case "$draft": self = .draft
        case "$deleted": self = .deleted  // not standard JMAP: JMAP deletes by moving between mailboxes
        default: self = .keyword(jmapKeyword)  // e.g. `$junk`, `$forwarded`, server-defined keywords
        }
    }

    /// `nil` for flags JMAP has no keyword for, so they are left out of ``Set/jmapKeywords``.
    public var jmapKeyword: String? {
        switch self {
        case .seen: "$seen"
        case .answered: "$answered"
        case .flagged: "$flagged"
        case .draft: "$draft"
        case .deleted: nil
        case .keyword(let keyword): keyword
        }
    }
}

// MARK: - Sets
extension Set<UnifiedFlag> {
    /// Converts the flags of an IMAP message.
    public init(imap flags: some Sequence<Flag>) {
        self = Set(flags.map(UnifiedFlag.init(imap:)))
    }

    public var imapFlags: [Flag] { map(\.imapFlag) }

    /// Converts the keywords of a JMAP message.
    public init(jmapKeywords: [String: Bool]) {
        self = Set(jmapKeywords.filter(\.value).keys.map(UnifiedFlag.init(jmapKeyword:)))
    }

    public var jmapKeywords: [String: Bool] {
        var keywords: [String: Bool] = [:]
        for flag in self {
            guard let keyword = flag.jmapKeyword else { continue }
            keywords[keyword] = true
        }
        return keywords
    }
}
