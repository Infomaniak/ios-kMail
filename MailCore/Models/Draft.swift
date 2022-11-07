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

public enum SaveDraftOption: String, Codable, PersistableEnum {
    case save
    case send
}

public enum ReplyMode: Equatable {
    case reply, replyAll
    case forward([Attachment])

    var isReply: Bool {
        return self == .reply || self == .replyAll
    }

    public static func == (lhs: ReplyMode, rhs: ReplyMode) -> Bool {
        switch (lhs, rhs) {
        case (.reply, .reply):
            return true
        case (.replyAll, .replyAll):
            return true
        case (.forward(_), .forward(_)):
            return true
        default:
            return false
        }
    }
}

public struct DraftResponse: Codable {
    public var uuid: String
    public var attachments: [Attachment]
    public var uid: String
}

public protocol AbstractDraft {
    var localUUID: String { get }
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
    public var localUUID: String
    public var remoteUUID: String
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
    public var attachments: [Attachment]?
    public var identityId: String
    public var messageUid: String?
    public var ackRequest = false
    public var stUuid: String?
    // uid?
    public var priority: MessagePriority
    public var action: SaveDraftOption?
    public var delay: Int?
    public var didSetSignature: Bool {
        return !identityId.isEmpty
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

    private init(localUUID: String = UUID().uuidString,
                 remoteUUID: String = "",
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
                 attachments: [Attachment]? = nil,
                 identityId: String = "",
                 messageUid: String? = nil,
                 ackRequest: Bool = false,
                 stUuid: String? = nil,
                 priority: MessagePriority = .normal,
                 action: SaveDraftOption? = nil,
                 delay: Int? = UserDefaults.shared.cancelSendDelay.rawValue) {
        self.localUUID = localUUID
        self.remoteUUID = remoteUUID
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
        self.attachments = attachments
        self.identityId = identityId
        self.messageUid = messageUid
        self.ackRequest = ackRequest
        self.stUuid = stUuid
        self.priority = priority
        self.action = action
        self.delay = delay
    }

    private enum CodingKeys: String, CodingKey {
        case remoteUUID = "uuid"
        case date
        case identityId
        case inReplyToUid
        case forwardedUid
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
        case action
        case delay
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(remoteUUID, forKey: .remoteUUID)
        try container.encode(identityId, forKey: .identityId)
        try container.encode(inReplyToUid, forKey: .inReplyToUid)
        try container.encode(forwardedUid, forKey: .forwardedUid)
        try container.encode(inReplyTo, forKey: .inReplyTo)
        try container.encode(mimeType, forKey: .mimeType)
        try container.encode(body, forKey: .body)
        try container.encode(quote, forKey: .quote)
        if !to.isEmpty {
            try container.encode(to, forKey: .to)
        }
        if !cc.isEmpty {
            try container.encode(cc, forKey: .cc)
        }
        if !bcc.isEmpty {
            try container.encode(bcc, forKey: .bcc)
        }
        try container.encode(subject, forKey: .subject)
        try container.encode(ackRequest, forKey: .ackRequest)
        try container.encode(priority, forKey: .priority)
        try container.encode(stUuid, forKey: .stUuid)
        let attachmentsArray = attachments?.map { attachment in
            attachment.uuid
        }
        try container.encode(attachmentsArray, forKey: .attachments)
        try container.encode(action, forKey: .action)
        try container.encode(delay, forKey: .delay)
    }

    private func valueToRecipient(_ value: String) -> [Recipient] {
        guard !value.isEmpty else { return [] }
        return value.components(separatedBy: ",").map { Recipient(email: $0, name: "") }
    }

    private func recipientToValue(_ recipient: [Recipient]) -> String {
        return recipient.map(\.email).joined(separator: ",")
    }

    public static func mailTo(subject: String?,
                              body: String?,
                              to: [Recipient], cc: [Recipient], bcc: [Recipient]) -> UnmanagedDraft {
        return UnmanagedDraft(subject: subject ?? "",
                              body: body ?? "",
                              to: to,
                              cc: cc,
                              bcc: bcc)
    }

    public static func empty() -> UnmanagedDraft {
        return UnmanagedDraft()
    }

    public static func writing(to recipient: Recipient) -> UnmanagedDraft {
        return UnmanagedDraft(to: [recipient.detached()])
    }

    public static func replying(to message: Message, mode: ReplyMode) -> UnmanagedDraft {
        let subject: String
        let quote: String
        var attachments: [Attachment] = []
        switch mode {
        case .reply, .replyAll:
            subject = "Re: \(message.formattedSubject)"
            quote = Constants.replyQuote(message: message)
        case let .forward(attachmentsToForward):
            subject = "Fwd: \(message.formattedSubject)"
            quote = Constants.forwardQuote(message: message)
            attachments = attachmentsToForward
        }

        var to: [Recipient] = []
        var cc: [Recipient] = []

        if mode.isReply {
            let userEmail = AccountManager.instance.currentMailboxManager?.mailbox.email ?? ""
            let cleanedFrom = Array(message.from.detached()).filter { $0.email != userEmail }
            let cleanedTo = Array(message.to.detached()).filter { $0.email != userEmail }
            let cleanedReplyTo = Array(message.replyTo.detached()).filter { $0.email != userEmail }
            let cleanedCc = Array(message.cc.detached()).filter { $0.email != userEmail }

            to = cleanedReplyTo.isEmpty ? cleanedFrom : cleanedReplyTo
            if to.isEmpty {
                to = cleanedTo
            } else if mode == .replyAll {
                cc = cleanedTo
            }
            if to.isEmpty {
                to = cleanedCc
            } else if mode == .replyAll {
                cc.append(contentsOf: cleanedCc)
            }
        }

        return UnmanagedDraft(subject: subject,
                              body: "<br><br>\(quote)",
                              quote: quote,
                              to: to,
                              cc: cc,
                              inReplyTo: message.msgId,
                              inReplyToUid: mode.isReply ? message.uid : nil,
                              forwardedUid: mode == .forward([]) ? message.uid : nil,
                              attachments: attachments)
    }

    public static func toUnmanaged(managedDraft: Draft) -> UnmanagedDraft {
        return UnmanagedDraft(localUUID: managedDraft.localUUID,
                              remoteUUID: managedDraft.remoteUUID,
                              subject: managedDraft.subject ?? "",
                              body: managedDraft.body,
                              quote: managedDraft.quote ?? "",
                              mimeType: managedDraft.mimeType,
                              to: Array(managedDraft.to.freezeIfNeeded()),
                              cc: Array(managedDraft.cc.freezeIfNeeded()),
                              bcc: Array(managedDraft.bcc.freezeIfNeeded()),
                              inReplyTo: managedDraft.inReplyTo,
                              inReplyToUid: managedDraft.inReplyToUid,
                              forwardedUid: managedDraft.forwardedUid,
                              identityId: managedDraft.identityId ?? "",
                              messageUid: managedDraft.messageUid,
                              ackRequest: managedDraft.ackRequest,
                              stUuid: managedDraft.stUuid,
                              priority: managedDraft.priority,
                              action: managedDraft.action)
    }

    public func asManaged() -> Draft {
        return Draft(localUUID: localUUID,
                     remoteUUID: remoteUUID,
                     identityId: identityId,
                     messageUid: messageUid,
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

    public mutating func setSignature(_ signatureResponse: SignatureResponse) {
        identityId = "\(signatureResponse.defaultSignatureId)"
        guard let signature = signatureResponse.default else {
            return
        }
        from = [Recipient(email: signature.sender, name: signature.fullName)]
        replyTo = [Recipient(email: signature.replyTo, name: "")]
        let html = "<br><br><div class=\"editorUserSignature\">\(signature.content)</div>"
        switch signature.position {
        case .beforeReplyMessage:
            body.insert(contentsOf: html, at: body.startIndex)
        case .afterReplyMessage:
            body.append(contentsOf: html)
        }
    }
}

public class Draft: Object, Decodable, Identifiable, AbstractDraft {
    @Persisted(primaryKey: true) public var localUUID: String
    @Persisted public var remoteUUID = ""
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
    @Persisted public var action: SaveDraftOption?

    private enum CodingKeys: String, CodingKey {
        case remoteUUID = "uuid"
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
    }

    override public init() {
        mimeType = UTType.html.preferredMIMEType!
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        remoteUUID = try values.decode(String.self, forKey: .remoteUUID)
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

    public convenience init(localUUID: String = UUID().uuidString,
                            remoteUUID: String = "",
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
                            isOffline: Bool = true,
                            action: SaveDraftOption? = nil) {
        self.init()

        self.localUUID = localUUID
        self.remoteUUID = remoteUUID
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
        self.action = action
    }

    public func asUnmanaged() -> UnmanagedDraft {
        return .toUnmanaged(managedDraft: self)
    }
}
