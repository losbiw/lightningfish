// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import GRDB

/// App-wide error vocabulary, thrown by the account, session and store layers.
public enum AccountError: CustomStringConvertible, Error, Equatable {
    case authorization(Error)
    case autoconfig(Error)
    case GRDB(Error)
    case imap(IMAPError)
    case jmap(JMAPError)
    case mime(MIMEError)
    /// Several failures from one operation, e.g. refreshing tokens for multiple accounts.
    case multiple([AccountError])
    case preferences(PreferencesError)
    case session(SessionError)
    case smtp(SMTPError)
    /// Any failure without a more specific case.
    case underlying(Error)

    /// Wraps any error, keeping known error types specific.
    public init(_ error: Error) {
        switch error {
        case let error as AccountError:
            self = error
        case let error as DatabaseError:
            self = .GRDB(error)
        case let error as IMAPError:
            self = .imap(error)
        case let error as JMAPError:
            self = .jmap(error)
        case let error as MIMEError:
            self = .mime(error)
        case let error as PreferencesError:
            self = .preferences(error)
        case let error as SessionError:
            self = .session(error)
        case let error as SMTPError:
            self = .smtp(error)
        default:
            self = .underlying(error)
        }
    }

    // MARK: CustomStringConvertible
    /// Developer-facing description, suitable for logs.
    public var description: String {
        switch self {
        case .authorization(let error): "Authorization: \(error)"
        case .autoconfig(let error): "Autoconfiguration: \(error)"
        case .GRDB(let error): "GRDB: \(error)"
        case .imap(let error): "IMAP: \(error)"
        case .jmap(let error): "JMAP: \(error)"
        case .mime(let error): "MIME: \(error)"
        case .multiple(let errors): errors.map(\.description).joined(separator: "; ")
        case .preferences(let error): "Preferences: \(error)"
        case .session(let error): "Session: \(error)"
        case .smtp(let error): "SMTP: \(error)"
        case .underlying(let error): "\(error)"
        }
    }

    // MARK: Equatable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.description == rhs.description
    }
}

// MARK: LocalizedError
extension AccountError: LocalizedError {
    /// User-facing summary, shown by error alerts.
    public var errorDescription: String? {
        switch self {
        case .authorization: "Your sign-in is no longer valid."
        case .autoconfig: "Couldn't look up the mail server settings for this address."
        case .GRDB: "Couldn't read or write local data."
        case .imap(let error): "\(error)"
        case .jmap(let error): "\(error)"
        case .mime(let error): "\(error)"
        case .multiple(let errors):
            (["\(errors.count) things went wrong:"] + errors.map { "• \($0.errorDescription ?? $0.description)" })
                .joined(separator: "\n")
        case .preferences(let error): "\(error)"
        case .session(let error): "\(error)"
        case .smtp(let error): "\(error)"
        case .underlying: "Something went wrong."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .authorization: "Sign in again to continue."
        case .GRDB: "Restart the app and try again."
        case .session: "Select a mailbox and try again."
        default: nil
        }
    }
}
