// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

public enum AccountError: CustomStringConvertible, Error, Equatable {
    case authorization(Error)
    case autoconfig(Error)
    case GRDB(Error)
    case imap(IMAPError)
    case jmap(JMAPError)
    case mime(MIMEError)
    case smtp(SMTPError)

    public init?(_ error: Error) {
        if let error: Self = error as? Self {
            self = error
        } else {
            switch error {
            case let error as IMAPError:
                self = .imap(error)
            case let error as JMAPError:
                self = .jmap(error)
            case let error as MIMEError:
                self = .mime(error)
            case let error as SMTPError:
                self = .smtp(error)
            default:
                return nil
            }
        }
    }

    // MARK: CustomStringConvertible
    public var description: String {
        switch self {
        case .authorization(let error): "Authorization: \(error)"
        case .autoconfig(let error): "Autoconfiguration: \(error)"
        case .GRDB(let error): "GRDB: \(error)"
        case .imap(let error): "IMAP: \(error)"
        case .jmap(let error): "JMAP: \(error)"
        case .mime(let error): "MIME: \(error)"
        case .smtp(let error): "SMTP: \(error)"
        }
    }

    // MARK: Equatable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.description == rhs.description
    }
}
