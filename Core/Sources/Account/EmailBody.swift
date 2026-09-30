// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import JMAP
import MIME

/// Common email body interface decoded from either `IMAP.Message` or `JMAP.Email`, encodable to `SMTP.Email`.
public struct EmailBody: Codable, CustomStringConvertible, Sendable {

    /// Format HTML body value with media attachments inlined as base64 data.
    public enum HTMLFormat: String, CustomStringConvertible {
        case inlineAttachments = "base64-encoded inline media attachments"
        case stripped = "HTML tags stripped"
        case none = "unmodified source"

        // MARK: CustomStringConvertible
        public var description: String { rawValue }
    }

    /// Every ``EmailAttachment`` decoded from `MIME.Body`, including both `ContentDisposition.attached` and `.inline`
    public let attachments: [EmailAttachment]

    /// Plain-text only or alternative message body
    public let text: String?

    /// HTML source decoded from message body with formatting options
    ///
    /// By default, related media attachments are inlined as base64-encoded data attributes`.
    public func html(_ format: HTMLFormat = .inlineAttachments) -> String? {
        switch format {
        case .inlineAttachments: _html?.inlining(attachments: attachments)
        case .stripped: _html?.htmlTagsStripped().htmlEntitiesDecoded()
        case .none: _html
        }
    }

    /// Plain text excerpt or summary of body contents, currently limited to server-provided values, described in [RFC 8970](https://www.rfc-editor.org/info/rfc8970)
    public var preview: String? {
        // TODO: For messages without a server-provided preview, derive excerpt locally
        _preview
    }

    public init(html: String? = nil, text: String? = nil, attachments: [EmailAttachment] = [], preview: String? = nil) {
        self.attachments = attachments
        self.text = text
        _preview = preview
        _html = html
    }

    private let _preview: String?
    private let _html: String?

    // MARK: CustomStringConvertible
    public var description: String { "" }
}

extension EmailBody {
    init(body: MIME.Body?) throws {
        guard let body, !body.isEmpty else {
            throw AccountError.mime(.dataNotFound)
        }
        let components: MIME.Part.Components = try body.part.components()
        let html: String? = !components.html.isEmpty ? components.html.joined() : nil
        let text: String? = !components.text.isEmpty ? components.text.joined() : nil
        let preview: String? = nil  // TODO: Generate preview text
        self.init(html: html, text: text, attachments: components.0, preview: preview)
    }

    init(email: JMAP.Email) throws {
        // TODO: JMAP email body decoding and assembly not implemented
        throw URLError(.cancelled)
    }
}

extension MIME.Body {
    var isEmpty: Bool { part.data.count < 1 }
}

extension MIME.Part {
    typealias Components = ([EmailAttachment], html: [String], text: [String])

    // Recursively decode and collect all subparts into component arrays
    func components(appendedTo components: Components? = nil) throws -> Components {
        var components: Components = components ?? ([], [], [])
        do {
            switch contentType {
            case .multipart:
                for part in try parts {
                    components = try part.components(appendedTo: components)
                }
            case .text(let subtype, let characterSet):
                let string: String = try String(
                    contentTransferEncoding,
                    data: data,
                    encoding: characterSet?.encoding ?? .utf8
                )
                switch subtype {
                case .html:
                    components.html.append(string)
                case .plain:
                    fallthrough
                default:  // All non-HTML email is plain text
                    components.text.append(string)
                }
            case .message:
                // Single `message/rfc822` type identifier exists for type `message`
                // "No encoding other than 7bit, 8bit, or binary is permitted for messages or parts of type message"
                // https://www.w3.org/Protocols/rfc1341/7_3_Message.html
                if let body: Body = try? Body(data) {
                    // TODO: Handle forwarded/attached message
                    print(body)
                } else if let text: String = try? String(contentTransferEncoding, data: data, encoding: .ascii) {
                    // TODO: Handle inline plain text message
                    print(text)
                }
            default:
                components.0.append(
                    EmailAttachment(
                        data: try data.decoded(from: contentTransferEncoding),
                        contentType: contentType,
                        contentDisposition: contentDisposition,
                        contentID: contentID
                    ))
            }
        } catch {
            throw error
        }
        // TODO: Encode inline attachments into HTML as base64 strings
        return components
    }
}

extension MIME.CharacterSet {
    var encoding: String.Encoding? {
        switch self {
        case .ascii: .ascii
        case .iso8859: .isoLatin1
        case .utf8: .utf8
        default: nil
        }
    }
}

extension String {

    // Decode `MIME.Part` data with any `ContentTransferEncoding` to `String` of any `String.Encoding`
    init(_ transferEncoding: ContentTransferEncoding?, data: Data, encoding: Encoding = .utf8) throws {
        switch transferEncoding {
        case .base64:
            do {
                try self.init(base64: data, encoding: encoding)  // Try strict decode first
            } catch {
                try self.init(nil, data: data, encoding: encoding)  // Try fuzzy (default) decode
            }
        case .quotedPrintable:
            do {
                try self.init(quotedPrintable: data, encoding: encoding)  // Try strict decode first
            } catch {
                try self.init(nil, data: data, encoding: encoding)  // Try fuzzy (default) decode
            }
        default:  // ASCII and unknown content transfer encodings
            guard let string: Self = Self(data: data, encoding: encoding) else {
                throw MIMEError.dataNotDecoded(data, encoding: encoding)
            }
            self = string
        }
    }
}
