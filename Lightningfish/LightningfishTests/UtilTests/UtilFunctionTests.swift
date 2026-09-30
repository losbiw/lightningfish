// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Testing

struct UtilFunctionTests {
    @Test func displayName_firstLastNames() async throws {
        #expect(createAvatarText(displayName: "Denny Klein") == "DK")
    }
    @Test func displayName_oneName() async throws {
        #expect(createAvatarText(displayName: "DennyKlein") == "D")
    }
    @Test func displayName_moreThanTwoNames() async throws {
        #expect(createAvatarText(displayName: "Denny Klein Two") == "DK")
    }
    @Test func displayName_empty() async throws {
        #expect(createAvatarText(displayName: "") == "")
    }
}
