// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Authorization credential  for a given user name, either an OAuth token or basic password
public enum Authorization: CustomStringConvertible, Equatable {
    case basic(user: String, password: String)
    case oauth(user: String, token: Token, refresh: Token)
    case none

    public var user: String {
        switch self {
        case .basic(let user, _), .oauth(let user, _, _): user
        case .none: ""
        }
    }

    /// Formatted `URLRequest` Authorization header value
    public var value: String {
        switch self {
        case .basic: "Basic \(password)"
        case .oauth: "Bearer \(password)"
        case .none: ""
        }
    }

    /// Encoded `URLCredential` password value (for keychain storage)
    public var password: String {
        switch self {
        case .basic(let user, let password):
            "\(user):\(password)".data(using: .utf8)!.base64EncodedString()
        case .oauth(_, let token, let refreshToken):
            "\(token):\(token.tokenExpiration?.timeIntervalSince1970, default: "0"):\(refreshToken)"
                .data(using: .utf8)!
                .base64EncodedString()
        case .none:
            ""
        }
    }

    public var isExpired: Bool {
        switch self {
        case .basic(_, _): false
        case .oauth(_, let token, _): token.isExpired
        case .none: true
        }
    }

    public var refreshToken: String? {
        switch self {
        case .oauth(_, _, let refreshToken): refreshToken.value
        case .basic, .none: nil
        }
    }

    /// Derive appropriate authorization case from naked `URLCredential` user/password strings.
    init(user: String, password: String?) {
        let password: String = password ?? ""
        if !user.isEmpty,
            let data: Data = Data(base64Encoded: password),
            let components: [String] = String(data: data, encoding: .utf8)?.components(separatedBy: ":")
        {
            switch components.count {
            case 3:
                let expDate: Date = Date(timeIntervalSince1970: TimeInterval(components[1]) ?? 0)
                self = .oauth(user: user, token: .bearer(components[0], expDate), refresh: .refresh(components[2]))
            case 2:
                self = .basic(user: user, password: components[1])
            default:
                self = .none
            }
        } else {
            self = .none
        }
    }

    // MARK: CustomStringConvertible
    public var description: String { value }
}
