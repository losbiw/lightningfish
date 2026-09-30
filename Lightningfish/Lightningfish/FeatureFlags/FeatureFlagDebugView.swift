// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

struct FeatureFlagDebugView: View {
    @Environment(FeatureFlags.self) private var flags: FeatureFlags
    @State private var allowRemoteFlags = false

    var body: some View {
        VStack {
            Toggle("all_remote_feature_flags", isOn: $allowRemoteFlags).padding()
            List(flags.featureList, id: \.self) { string in
                SettingRowView(string, flags.flagForKey(key: string))
            }
        }.onChange(of: allowRemoteFlags) {
            flags.setAllowRemoteFlags(allowRemote: allowRemoteFlags)
        }.task {
            allowRemoteFlags = flags.allowRemote
        }

    }
}

struct SettingRowView: View {
    init(_ flagName: String, _ onState: Bool) {

        self.flagName = flagName
        self.isOn = onState
    }

    @Environment(FeatureFlags.self) private var flags: FeatureFlags
    @State private var isOn: Bool
    private var flagName: String

    var body: some View {
        HStack {
            Toggle(flagName, isOn: $isOn)

        }.onChange(of: isOn) {
            flags.setFlagForKey(key: flagName, val: isOn)
        }
    }
}

#Preview("Feature Flag Settings") {
    @Previewable @State var flags: FeatureFlags = FeatureFlags(distribution: .current)

    FeatureFlagDebugView()
        .environment(flags)
}
