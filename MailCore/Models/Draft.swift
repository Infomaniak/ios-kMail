/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation
import MailResources
import RealmSwift
import UniformTypeIdentifiers

public enum SaveDraftOption: String, Codable {
    case save
    case send
}

public enum ReplyMode {
    case reply, replyAll, forward

    var isReply: Bool {
        return self == .reply || self == .replyAll
    }
}

public struct DraftResponse: Codable {
    public var uuid: String
    public var attachments: [Attachment]
    public var uid: String
}

public protocol AbstractDraft {
    var uuid: String { get }
}

@propertyWrapper public struct EmptyNilEncoded<Content>: Encodable, Equatable where Content: Encodable & Equatable {
    public var wrappedValue: [Content]

    public init(wrappedValue: [Content]) {
        self.wrappedValue = wrappedValue
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if wrappedValue.isEmpty {
            try container.encodeNil()
        } else {
            try container.encode(wrappedValue)
        }
    }
}

// We need two draft models because of a bug in Realm…
// https://github.com/realm/realm-swift/issues/7810
public struct UnmanagedDraft: Equatable, Encodable, AbstractDraft {
    public var uuid: String
    public var subject: String
    public var body: String
    public var quote: String
    public var mimeType: String
    @EmptyNilEncoded public var from: [Recipient]
    @EmptyNilEncoded public var replyTo: [Recipient]
    @EmptyNilEncoded public var to: [Recipient]
    @EmptyNilEncoded public var cc: [Recipient]
    @EmptyNilEncoded public var bcc: [Recipient]
    public var inReplyTo: String?
    public var inReplyToUid: String?
    public var forwardedUid: String?
    // attachments
    public var identityId: String
    public var ackRequest = false
    public var stUuid: String?
    // uid?
    public var priority: MessagePriority
    public var action: SaveDraftOption?
    public var delay: Int?

    public var hasLocalUuid: Bool {
        return uuid.isEmpty || uuid.starts(with: Draft.uuidLocalPrefix)
    }

    public var toValue: String {
        get {
            return recipientToValue(to)
        }
        set {
            to = valueToRecipient(newValue)
        }
    }

    public var ccValue: String {
        get {
            return recipientToValue(cc)
        }
        set {
            cc = valueToRecipient(newValue)
        }
    }

    public var bccValue: String {
        get {
            return recipientToValue(bcc)
        }
        set {
            bcc = valueToRecipient(newValue)
        }
    }

    public init(uuid: String = "",
                subject: String = "",
                body: String = "",
                quote: String = "",
                mimeType: String = UTType.html.preferredMIMEType!,
                from: [Recipient] = [],
                replyTo: [Recipient] = [],
                to: [Recipient] = [],
                cc: [Recipient] = [],
                bcc: [Recipient] = [],
                inReplyTo: String? = nil,
                inReplyToUid: String? = nil,
                forwardedUid: String? = nil,
                identityId: String = "",
                ackRequest: Bool = false,
                stUuid: String? = nil,
                priority: MessagePriority = .normal,
                action: SaveDraftOption? = nil,
                delay: Int? = UserDefaults.shared.cancelSendDelay.rawValue) {
        self.uuid = uuid
        self.subject = subject
        self.body = body
        self.quote = quote
        self.mimeType = mimeType
        self.from = from
        self.replyTo = replyTo
        self.to = to
        self.cc = cc
        self.bcc = bcc
        self.inReplyTo = inReplyTo
        self.inReplyToUid = inReplyToUid
        self.forwardedUid = forwardedUid
        self.identityId = identityId
        self.ackRequest = ackRequest
        self.stUuid = stUuid
        self.priority = priority
        self.action = action
        self.delay = delay
    }

    private func valueToRecipient(_ value: String) -> [Recipient] {
        guard !value.isEmpty else { return [] }
        return value.components(separatedBy: ",").map { Recipient(email: $0, name: "") }
    }

    private func recipientToValue(_ recipient: [Recipient]) -> String {
        return recipient.map(\.email).joined(separator: ",")
    }

    public static func writing(to recipient: Recipient) -> UnmanagedDraft {
        return UnmanagedDraft(to: [recipient.detached()])
    }

    public static func replying(to message: Message, mode: ReplyMode) -> UnmanagedDraft {
        let subject: String
        let quote: String
        switch mode {
        case .reply, .replyAll:
            subject = "Re: \(message.formattedSubject)"
            quote = Constants.replyQuote(message: message)
        case .forward:
            subject = "Fwd: \(message.formattedSubject)"
            quote = Constants.forwardQuote(message: message)
        }
        return UnmanagedDraft(subject: subject,
                              body: "<div><br></div><div><br></div>\(quote)",
                              quote: quote,
                              to: mode.isReply ? Array(message.replyTo.isEmpty ? message.from.detached() : message.replyTo.detached()) : [],
                              cc: mode == .replyAll ? Array(message.to.detached()) + Array(message.cc.detached()) : [],
                              inReplyTo: message.msgId,
                              inReplyToUid: mode.isReply ? message.uid : nil,
                              forwardedUid: mode == .forward ? message.uid : nil /* ,
                               attachments: mode == .forward ? Array(message.attachments) : nil */ )
    }

    public func asManaged() -> Draft {
        return Draft(uuid: uuid,
                     identityId: identityId,
                     inReplyToUid: inReplyToUid,
                     forwardedUid: forwardedUid,
                     inReplyTo: inReplyTo,
                     mimeType: mimeType,
                     body: body,
                     quote: quote,
                     to: to,
                     cc: cc,
                     bcc: bcc,
                     subject: subject,
                     ackRequest: ackRequest,
                     priority: priority,
                     stUuid: stUuid)
    }

    public mutating func setSender(signatureResponse: SignatureResponse) {
        identityId = "\(signatureResponse.defaultSignatureId)"
        guard let signature = signatureResponse.signatures.first(where: { $0.id == signatureResponse.defaultSignatureId }) else {
            return
        }
        from = [Recipient(email: signature.sender, name: signature.fullName)]
        replyTo = [Recipient(email: signature.replyTo, name: "")]
    }
}

public class Draft: Object, Decodable, Identifiable, AbstractDraft {
    public static let uuidLocalPrefix = "Local-"

    @Persisted(primaryKey: true) public var uuid: String = ""
    @Persisted public var date: Date
    @Persisted public var identityId: String?
    @Persisted public var messageUid: String?
    @Persisted public var inReplyToUid: String?
    @Persisted public var forwardedUid: String?
    @Persisted public var references: String?
    @Persisted public var inReplyTo: String?
    @Persisted public var mimeType: String
    @Persisted public var body: String
    @Persisted public var quote: String?
    @Persisted public var to: List<Recipient>
    @Persisted public var cc: List<Recipient>
    @Persisted public var bcc: List<Recipient>
    @Persisted public var subject: String?
    @Persisted public var ackRequest = false
    @Persisted public var priority: MessagePriority
    @Persisted public var stUuid: String?
    @Persisted public var attachments: List<Attachment>
    @Persisted public var isOffline = true

    public var hasLocalUuid: Bool {
        return uuid.isEmpty || uuid.starts(with: Draft.uuidLocalPrefix)
    }

    private enum CodingKeys: String, CodingKey {
        case uuid
        case date
        case identityId
        case inReplyToUid
        case forwardedUid
        case references
        case inReplyTo
        case mimeType
        case body
        case quote
        case to
        case cc
        case bcc
        case subject
        case ackRequest
        case priority
        case stUuid
        case attachments
        case isOffline
    }

    override public init() {
        mimeType = UTType.html.preferredMIMEType!
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try values.decode(String.self, forKey: .uuid)
        date = try values.decode(Date.self, forKey: .date)
        identityId = try values.decodeIfPresent(String.self, forKey: .identityId)
        inReplyToUid = try values.decodeIfPresent(String.self, forKey: .inReplyToUid)
        forwardedUid = try values.decodeIfPresent(String.self, forKey: .forwardedUid)
        references = try values.decodeIfPresent(String.self, forKey: .references)
        inReplyTo = try values.decodeIfPresent(String.self, forKey: .inReplyTo)
        mimeType = try values.decode(String.self, forKey: .mimeType)
        body = try values.decode(String.self, forKey: .body)
        quote = try values.decodeIfPresent(String.self, forKey: .quote)
        to = try values.decode(List<Recipient>.self, forKey: .to)
        cc = try values.decode(List<Recipient>.self, forKey: .cc)
        bcc = try values.decode(List<Recipient>.self, forKey: .bcc)
        subject = try values.decodeIfPresent(String.self, forKey: .subject)
        ackRequest = try values.decode(Bool.self, forKey: .ackRequest)
        priority = try values.decode(MessagePriority.self, forKey: .priority)
        stUuid = try values.decodeIfPresent(String.self, forKey: .stUuid)
        attachments = try values.decode(List<Attachment>.self, forKey: .attachments)
    }

    public convenience init(uuid: String = "",
                            date: Date = Date(),
                            identityId: String? = nil,
                            messageUid: String? = nil,
                            inReplyToUid: String? = nil,
                            forwardedUid: String? = nil,
                            references: String? = nil,
                            inReplyTo: String? = nil,
                            mimeType: String = UTType.html.preferredMIMEType!,
                            body: String = "",
                            quote: String? = nil,
                            to: [Recipient]? = nil,
                            cc: [Recipient]? = nil,
                            bcc: [Recipient]? = nil,
                            subject: String = "",
                            ackRequest: Bool = false,
                            priority: MessagePriority = .normal,
                            stUuid: String? = nil,
                            attachments: [Attachment]? = nil,
                            isOffline: Bool = true) {
        self.init()

        self.uuid = uuid
        self.date = date
        self.identityId = identityId
        self.messageUid = messageUid
        self.inReplyToUid = inReplyToUid
        self.forwardedUid = forwardedUid
        self.references = references
        self.inReplyTo = inReplyTo
        self.mimeType = mimeType
        self.body = body
        self.quote = quote
        self.to = to?.toRealmList() ?? List()
        self.cc = cc?.toRealmList() ?? List()
        self.bcc = bcc?.toRealmList() ?? List()
        self.subject = subject
        self.ackRequest = ackRequest
        self.priority = priority
        self.stUuid = stUuid
        self.attachments = attachments?.toRealmList() ?? List()
        self.isOffline = isOffline
    }

    public func asUnmanaged() -> UnmanagedDraft {
        return UnmanagedDraft(uuid: uuid,
                              subject: subject ?? "",
                              body: body,
                              quote: quote ?? "",
                              mimeType: mimeType,
                              to: Array(to),
                              cc: Array(cc),
                              bcc: Array(bcc),
                              inReplyTo: inReplyTo,
                              inReplyToUid: inReplyToUid,
                              forwardedUid: forwardedUid,
                              identityId: identityId ?? "",
                              ackRequest: ackRequest,
                              stUuid: stUuid,
                              priority: priority)
    }
}
