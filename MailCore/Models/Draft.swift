/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation
import RealmSwift
import SwiftSoup
import UniformTypeIdentifiers

extension String {
    var trimmed: String {
        let whiteSpaceSet = NSCharacterSet.whitespacesAndNewlines
        return trimmingCharacters(in: whiteSpaceSet)
    }
}

public enum SaveDraftOption: String, Codable, PersistableEnum {
    case initialSave
    case save
    case send
    case sendReaction = "send_reaction"
    case schedule

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .initialSave, .save:
            try container.encode(SaveDraftOption.save.rawValue)
        case .send, .sendReaction, .schedule:
            try container.encode(rawValue)
        }
    }
}

public enum ReplyMode: String, Codable, Hashable, Equatable {
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

public final class Draft: Object, Codable, ObjectKeyIdentifiable {
    public static let reactionPlaceholder = "<div>__REACTION_PLACEMENT__<br></div>"

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
    @Persisted public var rawSignature: String?
    @Persisted public var scheduleDate: Date?
    @Persisted public var emojiReaction: String?
    @Persisted public var encrypted: Bool
    @Persisted public var encryptionPassword: String

    public var allRecipients: [Recipient] {
        return to.toArray() + cc.toArray() + bcc.toArray()
    }

    public var autoEncryptDisabledRecipients: [Recipient] {
        return allRecipients.filter { recipient in
            if !recipient.canAutoEncrypt {
                return true
            }
            return false
        }
    }

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

    public var isLoadedRemotely: Bool {
        messageUid != nil && remoteUUID.isEmpty
    }

    public var isReaction: Bool {
        emojiReaction != nil
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
        case scheduleDate
        case emojiReaction
        case encrypted
        case encryptionPassword
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
        mimeType = try values.decodeIfPresent(String.self, forKey: .mimeType) ?? UTType.html.preferredMIMEType!
        to = try values.decode(List<Recipient>.self, forKey: .to)
        cc = try values.decode(List<Recipient>.self, forKey: .cc)
        bcc = try values.decode(List<Recipient>.self, forKey: .bcc)
        subject = try values.decodeIfPresent(String.self, forKey: .subject) ?? ""
        ackRequest = try values.decode(Bool.self, forKey: .ackRequest)
        priority = try values.decode(MessagePriority.self, forKey: .priority)
        swissTransferUuid = try values.decodeIfPresent(String.self, forKey: .swissTransferUuid)
        attachments = try values.decode(List<Attachment>.self, forKey: .attachments)
        scheduleDate = try values.decodeIfPresent(Date.self, forKey: .scheduleDate)
        emojiReaction = try values.decodeIfPresent(String.self, forKey: .emojiReaction)
        encrypted = try values.decodeIfPresent(Bool.self, forKey: .encrypted) ?? false
        encryptionPassword = try values.decodeIfPresent(String.self, forKey: .encryptionPassword) ?? ""
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
                            action: SaveDraftOption? = nil,
                            emojiReaction: String? = nil,
                            encrypted: Bool = false) {
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
        self.emojiReaction = emojiReaction
        self.encrypted = encrypted
        encryptionPassword = ""
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

    public static func replying(reply: MessageReply, currentMailboxEmail: String) -> Draft {
        let message = reply.frozenMessage
        let mode = reply.replyMode
        let encrypted = message.encrypted
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
            recipientHolder = message.recipientsForReplyTo(replyAll: mode == .replyAll, currentMailboxEmail: currentMailboxEmail)
        }

        return Draft(localUUID: UUID().uuidString,
                     inReplyToUid: mode.isReply ? message.uid : nil,
                     forwardedUid: mode == .forward ? message.uid : nil,
                     references: "\(message.references ?? "") \(message.messageId ?? "")",
                     inReplyTo: message.messageId,
                     subject: subject,
                     body: "",
                     to: recipientHolder.to,
                     cc: recipientHolder.cc,
                     encrypted: encrypted)
    }

    public static func reacting(with reaction: String, reply: MessageReply, currentMailboxEmail: String) -> Draft {
        let replyingDraft = Draft.replying(reply: reply, currentMailboxEmail: currentMailboxEmail)

        replyingDraft.action = .sendReaction
        replyingDraft.emojiReaction = reaction
        replyingDraft.delay = 5

        return replyingDraft
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
        try container.encodeIfPresent(delay, forKey: .delay)
        try container.encodeIfPresent(scheduleDate, forKey: .scheduleDate)
        try container.encodeIfPresent(emojiReaction, forKey: .emojiReaction)
        try container.encode(encrypted, forKey: .encrypted)
        try container.encode(encryptionPassword, forKey: .encryptionPassword)
    }
}

public extension Draft {
    /// Returns the available attachments slots
    var availableAttachmentsSlots: Int {
        let maxBound = 96
        let offset = min(attachments.count, maxBound)
        let available = max(maxBound - offset, 0)
        return available
    }
}

public extension Draft {
    /// Compute if the draft has external recipients
    func displayExternalTag(mailboxManager: MailboxManager) -> DisplayExternalRecipientStatus.State {
        let recipientsList = List<Recipient>()
        recipientsList.append(objectsIn: cc)
        recipientsList.append(objectsIn: bcc)
        recipientsList.append(objectsIn: to)
        return displayExternalRecipientState(mailboxManager: mailboxManager, recipientsList: recipientsList)
    }

    func displayExternalRecipientState(mailboxManager: MailboxManager,
                                       recipientsList: List<Recipient>) -> DisplayExternalRecipientStatus.State {
        let externalDisplayStatus = DisplayExternalRecipientStatus(mailboxManager: mailboxManager, recipientsList: recipientsList)
        return externalDisplayStatus.state
    }
}

public extension Draft {
    /// List of HTML classes of elements added to the content of an email
    static let appendedHTMLElements = [
        Constants.signatureHTMLClass,
        Constants.forwardQuoteHTMLClass,
        Constants.replyQuoteHTMLClass
    ]

    /// Check that the draft has some Attachments of not
    var hasAttachments: Bool {
        return !attachments.filter { $0.contentId == nil }.isEmpty
    }

    /// Check if once the signature, the reply quote and the forward quote nodes removed, we still have content
    var isEmptyOfUserChanges: Bool {
        isEmpty(removeAllElements: true)
    }

    /// Check if the Signature has changes or not
    var isSignatureUnchanged: Bool {
        guard !body.isEmpty, let document = try? SwiftSoup.parse(body) else {
            return true
        }

        guard let signatureNode = try? document.getElementsByClass(Constants.signatureHTMLClass).first() else {
            return true
        }

        // We check if the signature was changed, the user might also have written within the signature div without knowing.
        let signatureNodeText = try? signatureNode.text()
        guard let rawSignature,
              let signatureNodeText,
              let rawSignatureDocument = try? SwiftSoup.parse(rawSignature),
              let rawSignatureText = try? rawSignatureDocument.text(),
              rawSignatureText.trimmed == signatureNodeText.trimmed else {
            return false
        }

        return true
    }

    var shouldBeSaved: Bool {
        guard !hasAttachments, isEmpty(removeAllElements: false), isSignatureUnchanged else {
            return false
        }
        return true
    }

    /// Check if once the signature node is removed, as well as the reply and forward quotes if `removeAllElements` is true, we
    /// still have content
    private func isEmpty(removeAllElements: Bool) -> Bool {
        guard !body.isEmpty, let document = try? SwiftSoup.parse(body) else { return true }

        let itemsToExtract = removeAllElements ? Self.appendedHTMLElements : [Constants.signatureHTMLClass]
        for itemToExtract in itemsToExtract {
            _ = try? document.getElementsByClass(itemToExtract).remove()
        }

        return !document.hasText()
    }
}
