// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

///While Alerts may have different UIs we will most likely not want more than one appearing at a time
///A single manager across the app prevents overlap or hidden alerts and allows for a unified format
@MainActor
@Observable class AlertManager {
    static let shared = AlertManager()

    var showAlert: Bool = false
    var alertTitle: String?
    var alertMessage: String?

    private init() {}  // Prevent creating multiple instances
}
