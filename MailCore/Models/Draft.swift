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
    case initialSave
    case save
    case send

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .initialSave, .save:
            try container.encode(SaveDraftOption.save.rawValue)
        case .send:
            try container.encode(SaveDraftOption.send.rawValue)
        }
    }
}

public enum ReplyMode: Equatable {
    case reply, replyAll
    case forward

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
    @Persisted(primaryKey: true) public var localUUID = UUID().uuidString
    @Persisted public var remoteUUID = ""
    @Persisted public var date = Date()
    @Persisted public var identityId: String?
    @Persisted public var messageUid: String?
    @Persisted public var inReplyToUid: String?
    @Persisted public var forwardedUid: String?
    @Persisted public var references: String?
    @Persisted public var inReplyTo: String?
    @Persisted public var mimeType: String = UTType.html.preferredMIMEType!
    @Persisted public var to: List<Recipient>
    @Persisted public var cc: List<Recipient>
    @Persisted public var bcc: List<Recipient>
    @Persisted public var subject = ""
    @Persisted public var ackRequest = false
    @Persisted public var priority: MessagePriority = .normal
    @Persisted public var swissTransferUuid: String?
    @Persisted public var attachments: List<Attachment>
    @Persisted public var action: SaveDraftOption?
    @Persisted public var delay: Int?

    /// Public facing "body", wrapping `bodyData`
    public var body: String {
        get {
            guard let decompressedString = bodyData?.decompressedString() else {
                return ""
            }

            return decompressedString
        } set {
            guard let data = newValue.compressed() else {
                bodyData = nil
                return
            }

            bodyData = data
        }
    }

    /// Store compressed data to reduce realm size.
    @Persisted var bodyData: Data?

    public var recipientsAreEmpty: Bool {
        to.isEmpty && cc.isEmpty && bcc.isEmpty
    }

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
        case to
        case cc
        case bcc
        case subject
        case ackRequest
        case priority
        case swissTransferUuid = "stUuid"
        case attachments
        case action
        case delay
    }

    override public init() { /* Realm needs an empty constructor */ }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        var buffer = try values.decode(String.self, forKey: .body)
        buffer = String.truncatedForRealmIfNeeded(buffer)
        if let compressedData = buffer.compressed() {
            bodyData = compressedData
        }

        remoteUUID = try values.decode(String.self, forKey: .remoteUUID)
        date = try values.decode(Date.self, forKey: .date)
        identityId = try values.decodeIfPresent(String.self, forKey: .identityId)
        inReplyToUid = try values.decodeIfPresent(String.self, forKey: .inReplyToUid)
        forwardedUid = try values.decodeIfPresent(String.self, forKey: .forwardedUid)
        references = try values.decodeIfPresent(String.self, forKey: .references)
        inReplyTo = try values.decodeIfPresent(String.self, forKey: .inReplyTo)
        mimeType = try values.decode(String.self, forKey: .mimeType)
        to = try values.decode(List<Recipient>.self, forKey: .to)
        cc = try values.decode(List<Recipient>.self, forKey: .cc)
        bcc = try values.decode(List<Recipient>.self, forKey: .bcc)
        subject = try values.decodeIfPresent(String.self, forKey: .subject) ?? ""
        ackRequest = try values.decode(Bool.self, forKey: .ackRequest)
        priority = try values.decode(MessagePriority.self, forKey: .priority)
        swissTransferUuid = try values.decodeIfPresent(String.self, forKey: .swissTransferUuid)
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
                            subject: String = "",
                            body: String = "",
                            to: [Recipient]? = nil,
                            cc: [Recipient]? = nil,
                            bcc: [Recipient]? = nil,
                            ackRequest: Bool = false,
                            priority: MessagePriority = .normal,
                            swissTransferUuid: String? = nil,
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
        self.to = to?.toRealmList() ?? List()
        self.cc = cc?.toRealmList() ?? List()
        self.bcc = bcc?.toRealmList() ?? List()
        self.subject = subject
        self.ackRequest = ackRequest
        self.priority = priority
        self.swissTransferUuid = swissTransferUuid
        self.attachments = attachments?.toRealmList() ?? List()
        self.action = action
    }

    public static func mailTo(urlComponents: URLComponents) -> Draft {
        let subject = urlComponents.getQueryItem(named: "subject")
        let body = urlComponents.getQueryItem(named: "body")?
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: "<br>")
        let to = Recipient.createListUsing(listOfAddresses: urlComponents.path)
            + Recipient.createListUsing(from: urlComponents, name: "to")
        let cc = Recipient.createListUsing(from: urlComponents, name: "cc")
        let bcc = Recipient.createListUsing(from: urlComponents, name: "bcc")

        return Draft(subject: subject ?? "", body: body ?? "", to: to, cc: cc, bcc: bcc)
    }

    public static func writing(to recipient: Recipient) -> Draft {
        return Draft(to: [recipient.detached()])
    }

    public static func replyingBody(message: Message, replyMode: ReplyMode) -> String {
        let unsafeQuote: String
        switch replyMode {
        case .reply, .replyAll:
            unsafeQuote = Constants.replyQuote(message: message)
        case .forward:
            unsafeQuote = Constants.forwardQuote(message: message)
        }

        let quote = (try? MessageWebViewUtils.cleanHtmlContent(rawHtml: unsafeQuote)?.outerHtml()) ?? ""

        return "<br><br>" + quote
    }

    public static func replying(reply: MessageReply) -> Draft {
        let message = reply.message
        let mode = reply.replyMode
        var subject = "\(message.formattedSubject)"
        switch mode {
        case .reply, .replyAll:
            if !subject.starts(with: "Re: ") {
                subject = "Re: \(subject)"
            }
        case .forward:
            if !subject.starts(with: "Fwd: ") {
                subject = "Fwd: \(subject)"
            }
        }

        var recipientHolder = RecipientHolder()

        if mode.isReply {
            recipientHolder = message.recipientsForReplyTo(replyAll: mode == .replyAll)
        }

        return Draft(localUUID: reply.localDraftUUID,
                     inReplyToUid: mode.isReply ? message.uid : nil,
                     forwardedUid: mode == .forward ? message.uid : nil,
                     references: "\(message.references ?? "") \(message.messageId ?? "")",
                     inReplyTo: message.messageId,
                     subject: subject,
                     body: "",
                     to: recipientHolder.to,
                     cc: recipientHolder.cc)
    }

    public func setSignature(_ signatureResponse: SignatureResponse) {
        identityId = "\(signatureResponse.defaultSignatureId)"
        guard let signature = signatureResponse.default else {
            return
        }

        let html = "<br><br><div class=\"editorUserSignature\">\(signature.content)</div>"
        switch signature.position {
        case .beforeReplyMessage:
            body.insert(contentsOf: html, at: body.startIndex)
        case .afterReplyMessage:
            body.append(contentsOf: html)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(remoteUUID, forKey: .remoteUUID)
        try container.encode(identityId, forKey: .identityId)
        try container.encode(inReplyToUid, forKey: .inReplyToUid)
        try container.encode(forwardedUid, forKey: .forwardedUid)
        try container.encode(inReplyTo, forKey: .inReplyTo)
        try container.encode(references, forKey: .references)
        try container.encode(mimeType, forKey: .mimeType)
        try container.encode(body, forKey: .body)
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
        try container.encode(swissTransferUuid, forKey: .swissTransferUuid)
        let attachmentsArray = Array(attachments.compactMap { $0.uuid })
        try container.encode(attachmentsArray, forKey: .attachments)
        try container.encode(action, forKey: .action)
        try container.encode(delay, forKey: .delay)
    }
}
