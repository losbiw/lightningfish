// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension URLProtectionSpace {

    // Named secure realm for lightningfish app-owned accounts on the keychain
    static let account: URLProtectionSpace = URLProtectionSpace(host: "lightningfish.net")

    convenience init(host: String) {
        self.init(host: host, port: 0, protocol: "https", realm: nil, authenticationMethod: nil)
    }
}
