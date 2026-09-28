// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension URLCredentialStorage {
    func authorization(for user: String, space: URLProtectionSpace = .account) -> Authorization? {
        credentials(for: space)?[user]?.authorization
    }

    func set(authorization: Authorization, persistence: URLCredential.Persistence = .permanent, space: URLProtectionSpace = .account) {
        set(URLCredential(authorization: authorization, persistence: persistence), for: space)
    }

    func deleteAuthorization(for user: String, space: URLProtectionSpace = .account) {
        guard let credential: URLCredential = credentials(for: space)?[user] else { return }
        remove(credential, for: space)
    }

    func deleteAuthorizations(space: URLProtectionSpace = .account) {
        for credential in (credentials(for: space) ?? [:]).values {
            remove(credential, for: space)
        }
    }
}

extension URLCredential {
    var authorization: Authorization? {
        guard let user, let password else { return nil }
        return Authorization(user: user, password: password)
    }

    convenience init(authorization: Authorization, persistence: Persistence = .permanent) {
        self.init(user: authorization.user, password: authorization.password, persistence: persistence)
    }
}
