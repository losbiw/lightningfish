// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Testing

struct FeatureFlagTests {
    @MainActor @Test func allowRemoteFlagsTest() {
        let allowRemote: Bool = FeatureFlags(distribution: .current).allowRemote  // Capture current setting
        FeatureFlags.resetAllowRemoteFlags()  // Reset to default value for test
        let flags: FeatureFlags = FeatureFlags(distribution: .current)
        #expect(flags.allowRemote == true)  // Expected default
        flags.setAllowRemoteFlags(allowRemote: false)
        #expect(flags.allowRemote == false)
        flags.setAllowRemoteFlags(allowRemote: allowRemote)  // Restore user setting
    }

    @MainActor @Test func flagForKeyTest() {
        FeatureFlags.resetFeatureFlags(distribution: .current)
        let flags: FeatureFlags = FeatureFlags(distribution: .current)
        #expect(flags.flagForKey(key: Flag.featureX.rawValue) == false)  // Expected default
        flags.setFlagForKey(key: Flag.featureX.rawValue, val: true)
        #expect(flags.flagForKey(key: Flag.featureX.rawValue) == true)
        FeatureFlags.resetFeatureFlags()
    }

    @MainActor @Test func setFlagForKeyTest() {
        FeatureFlags.resetFeatureFlags(distribution: .current)
        let flags: FeatureFlags = FeatureFlags(distribution: .current)
        #expect(flags.flagForKey(key: Flag.featureX.rawValue) == false)  // Expected default
        #expect(flags.flagForKey(key: Flag.featureY.rawValue) == false)  // Expected default
        flags.setFlagForKey(key: Flag.featureX.rawValue, val: true)
        #expect(flags.flagForKey(key: Flag.featureX.rawValue) == true)
        #expect(flags.flagForKey(key: Flag.featureY.rawValue) == false)
        flags.setFlagForKey(key: Flag.featureY.rawValue, val: true)
        #expect(flags.flagForKey(key: Flag.featureX.rawValue) == true)
        #expect(flags.flagForKey(key: Flag.featureY.rawValue) == true)
        flags.setFlagForKey(key: Flag.featureX.rawValue, val: false)
        #expect(flags.flagForKey(key: Flag.featureX.rawValue) == false)
        #expect(flags.flagForKey(key: Flag.featureY.rawValue) == true)
        FeatureFlags.resetFeatureFlags()
    }
}
