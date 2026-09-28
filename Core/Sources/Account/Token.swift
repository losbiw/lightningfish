// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum Token: CustomStringConvertible, Equatable {
    case bearer(String, Date)
    case refresh(String)

    var value: String {
        switch self {
        case .bearer(let token, _), .refresh(let token): token
        }
    }

    var isExpired: Bool {
        switch self {
        case .bearer(_, let expiration): Date() > expiration
        case .refresh(_): false
        }
    }

    var tokenExpiration: Date? {
        switch self {
        case .bearer(_, let expiration): expiration
        case .refresh(_): nil
        }
    }

    public init(value: String, expiration: Date) {
        self = .bearer(value, expiration)
    }

    public init(value: String) {
        self = .refresh(value)
    }

    // MARK: CustomStringConvertible
    public var description: String { value }
}
