// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Enable different features, load different settings, etc, based on build settings
public enum Distribution: Sendable {
    case debug
    case appstore
    case beta
}

extension Distribution {
    public static var current: Self {
        #if RELEASE
        return .appstore
        #elseif BETA
        return .beta
        #else
        return .debug
        #endif
    }
}
