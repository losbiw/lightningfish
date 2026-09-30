// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Account
import IMAP
import Testing

struct UnifiedFlagTests {
    @Test func fromIMAP() {
        #expect(UnifiedFlag(imap: .seen) == .seen)
        #expect(UnifiedFlag(imap: .answered) == .answered)
        #expect(UnifiedFlag(imap: .flagged) == .flagged)
        #expect(UnifiedFlag(imap: .draft) == .draft)
        #expect(UnifiedFlag(imap: .deleted) == .deleted)

        // IMAP flags are case-insensitive
        #expect(UnifiedFlag(imap: Flag("\\SEEN")) == .seen)

        // Everything else keeps the spelling the server used
        #expect(UnifiedFlag(imap: Flag("\\Important")) == .keyword("\\Important"))
        #expect(UnifiedFlag(imap: Flag("NonJunk")) == .keyword("NonJunk"))
        #expect(UnifiedFlag(imap: Flag("\\Recent")) == .keyword("\\Recent"))
    }

    @Test func toIMAP() {
        #expect(UnifiedFlag.seen.imapFlag == .seen)
        #expect(UnifiedFlag.keyword("NonJunk").imapFlag == Flag("NonJunk"))
        // `imapFlags` is a list, and set order is not stable, so compare as a set
        #expect(Set(Set<UnifiedFlag>.init(imap: [.seen, Flag("NonJunk")]).imapFlags) == [.seen, Flag("NonJunk")])
    }

    @Test func fromJMAP() {
        #expect(UnifiedFlag(jmapKeyword: "$seen") == .seen)
        #expect(UnifiedFlag(jmapKeyword: "$answered") == .answered)
        #expect(UnifiedFlag(jmapKeyword: "$flagged") == .flagged)
        #expect(UnifiedFlag(jmapKeyword: "$draft") == .draft)

        // JMAP-only keywords are kept as-is
        #expect(UnifiedFlag(jmapKeyword: "$junk") == .keyword("$junk"))
        #expect(UnifiedFlag(jmapKeyword: "$forwarded") == .keyword("$forwarded"))

        // Only keywords that are set (`true`) count
        #expect(Set<UnifiedFlag>(jmapKeywords: ["$seen": true, "$flagged": false]) == [.seen])
    }

    @Test func toJMAP() {
        #expect(UnifiedFlag.seen.jmapKeyword == "$seen")
        #expect(UnifiedFlag.keyword("$junk").jmapKeyword == "$junk")

        // Deletion has no JMAP keyword: JMAP deletes by moving messages between mailboxes
        #expect(UnifiedFlag.deleted.jmapKeyword == nil)
        #expect(Set<UnifiedFlag>([.seen, .deleted]).jmapKeywords == ["$seen": true])
    }

    @Test func roundTrip() {
        let flags: Set<UnifiedFlag> = [.seen, .flagged, .keyword("\\Important"), .keyword("NonJunk")]

        #expect(Set<UnifiedFlag>(imap: Set(flags.imapFlags)) == flags)
        #expect(Set<UnifiedFlag>(jmapKeywords: flags.jmapKeywords) == [.seen, .flagged, .keyword("\\Important"), .keyword("NonJunk")])
    }

    @Test func unread() {
        #expect(Email(flags: []).unread)
        #expect(!Email(flags: [.seen]).unread)
    }
}
