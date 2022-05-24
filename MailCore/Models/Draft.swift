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

public class Draft: Object, Codable, Identifiable {
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
    public var action: SaveDraftOption?

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

    public var subjectValue: String {
        get {
            return subject ?? ""
        }
        set {
            subject = newValue
        }
    }

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
        case action
    }

    override public init() {
        mimeType = "text/html"
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

    public convenience init(
        uuid: String = "",
        date: Date = Date(),
        identityId: String? = nil,
        messageUid: String? = nil,
        inReplyToUid: String? = nil,
        forwardedUid: String? = nil,
        references: String? = nil,
        inReplyTo: String? = nil,
        mimeType: String = "text/html",
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
        action: SaveDraftOption? = nil
    ) {
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
        self.action = action
    }

    public class func replying(to message: Message, mode: ReplyMode) -> Draft {
        let subject: String
        switch mode {
        case .reply, .replyAll:
            subject = "Re: \(message.formattedSubject)"
        case .forward:
            subject = "Fwd: \(message.formattedSubject)"
        }
        let headerText = MailResourcesStrings.messageReplyHeader(message.date.ISO8601Format(), message.from.first?.htmlDescription ?? "")
        let quote = "<div id=\"answerContentMessage\" class=\"ik_mail_quote\" ><div>\(headerText)</div><blockquote class=\"ws-ng-quote\"><div class=\"ik_mail_quote-6057eJzz9HPyjwAABGYBgQ\">\(message.body?.value.replacingOccurrences(of: "'", with: "’") ?? "")</div></blockquote></div>"
        return Draft(inReplyToUid: mode.isReply ? message.uid : nil,
                     forwardedUid: mode == .forward ? message.uid : nil,
                     inReplyTo: message.msgId,
                     body: "<div><br></div><div><br></div>\(quote)",
                     quote: quote,
                     to: mode.isReply ? Array(message.replyTo.isEmpty ? message.from.detached() : message.replyTo.detached()) : nil,
                     cc: mode == .replyAll ? Array(message.to.detached()) + Array(message.cc.detached()) : nil,
                     subject: subject,
                     attachments: mode == .forward ? Array(message.attachments) : nil)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(uuid, forKey: .uuid)
        try container.encode(date, forKey: .date)
        try container.encode(identityId, forKey: .identityId)
        try container.encode(inReplyToUid, forKey: .inReplyToUid)
        try container.encode(forwardedUid, forKey: .forwardedUid)
        try container.encode(references, forKey: .references)
        try container.encode(inReplyTo, forKey: .inReplyTo)
        try container.encode(mimeType, forKey: .mimeType)
        try container.encode(body, forKey: .body)
        try container.encode(quote, forKey: .quote)
        if to.isEmpty {
            try container.encodeNil(forKey: .to)
        } else {
            try container.encode(to, forKey: .to)
        }
        if cc.isEmpty {
            try container.encodeNil(forKey: .cc)
        } else {
            try container.encode(cc, forKey: .cc)
        }
        if bcc.isEmpty {
            try container.encodeNil(forKey: .bcc)
        } else {
            try container.encode(bcc, forKey: .bcc)
        }
        try container.encode(subject, forKey: .subject)
        try container.encode(ackRequest, forKey: .ackRequest)
        try container.encode(priority, forKey: .priority)
        try container.encode(stUuid, forKey: .stUuid)
        try container.encode(isOffline, forKey: .isOffline)
        try container.encode(action, forKey: .action)
    }

    private func valueToRecipient(_ value: String) -> List<Recipient> {
        guard !value.isEmpty else { return List<Recipient>() }
        return value.components(separatedBy: ",").map { Recipient(email: $0, name: "") }.toRealmList()
    }

    private func recipientToValue(_ recipient: List<Recipient>?) -> String {
        return recipient?.map(\.email).joined(separator: ",") ?? ""
    }
}
