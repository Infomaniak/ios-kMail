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

public class MessageUidsResult: Decodable {
    public let messageShortUids: [Int]
    public let cursor: String

    private enum CodingKeys: String, CodingKey {
        case messageShortUids = "messagesUids"
        case cursor = "signature"
    }
}

public class MessageByUidsResult: Decodable {
    public let messages: [Message]
}

public class MessageDeltaResult: Decodable {
    public let deletedShortUids: [Int]
    public let addedShortUids: [String]
    public let updated: [MessageFlags]
    public let cursor: String

    private enum CodingKeys: String, CodingKey {
        case deletedShortUids = "deleted"
        case addedShortUids = "added"
        case updated
        case cursor = "signature"
    }
}

public class MessageFlags: Decodable {
    public let shortUid: String
    public let answered: Bool
    public let isFavorite: Bool
    public let forwarded: Bool
    public let scheduled: Bool
    public let seen: Bool

    private enum CodingKeys: String, CodingKey {
        case shortUid = "uid"
        case answered
        case isFavorite = "flagged"
        case forwarded
        case scheduled
        case seen
    }
}

public enum MessagePriority: String, Codable, PersistableEnum {
    case low, normal, high
}

public enum MessageDKIM: String, Codable, PersistableEnum {
    case valid
    case notValid = "not_valid"
    case notSigned = "not_signed"
}

public class Message: Object, Decodable, Identifiable {
    @Persisted(primaryKey: true) public var uid = ""
    @Persisted public var messageId: String?
    @Persisted public var subject: String?
    @Persisted public var priority: MessagePriority
    @Persisted public var date: Date
    @Persisted public var size: Int
    @Persisted public var from: List<Recipient>
    @Persisted public var to: List<Recipient>
    @Persisted public var cc: List<Recipient>
    @Persisted public var bcc: List<Recipient>
    @Persisted public var replyTo: List<Recipient>
    @Persisted public var body: Body?
    @Persisted public var attachments: List<Attachment>
    @Persisted public var dkimStatus: MessageDKIM
    @Persisted public var attachmentsResource: String?
    @Persisted public var resource: String
    @Persisted public var downloadResource: String
    @Persisted public var draftResource: String?
    @Persisted public var stUuid: String?
    @Persisted public var folderId: String
    @Persisted public var folder: String
    @Persisted public var references: String?
    @Persisted public var inReplyTo: String?
    @Persisted public var linkedUids: MutableSet<String>
    @Persisted public var preview: String
    @Persisted public var answered: Bool
    @Persisted public var isDuplicate: Bool?
    @Persisted public var isDraft: Bool
    @Persisted public var hasAttachments: Bool
    @Persisted public var seen: Bool
    @Persisted public var scheduled: Bool
    @Persisted public var forwarded: Bool
    @Persisted public var flagged: Bool
    @Persisted public var safeDisplay: Bool?
    @Persisted public var hasUnsubscribeLink: Bool?
    @Persisted(originProperty: "messages") var parents: LinkingObjects<Thread>

    @Persisted public var fullyDownloaded = false
    @Persisted public var fromSearch = false
    @Persisted public var inTrash = false

    public var recipients: [Recipient] {
        return Array(to) + Array(cc)
    }

    public var originalParent: Thread? {
        return parents.first { $0.folderId == folderId }
    }

    public var shouldComplete: Bool {
        return isDraft || !fullyDownloaded
    }

    public var formattedSubject: String {
        return subject ?? MailResourcesStrings.Localizable.noSubjectTitle
    }

    public var attachmentsSize: Int64 {
        return attachments.reduce(0) { $0 + $1.size }
    }

    public func insertInlineAttachment() {
        for attachment in attachments {
            if let contentId = attachment.contentId, let value = body?.value, let resource = attachment.resource {
                body?.value = value.replacingOccurrences(
                    of: "cid:\(contentId)",
                    with: "\(URLSchemeHandler.scheme)\(URLSchemeHandler.domain)\(resource)"
                )
            }
        }
    }

    public func computeReference() {
        if var refs = references, !refs.isEmpty {
            refs.removeFirst()
            refs.removeLast()
            refs = refs.replacingOccurrences(of: "> <", with: "><")
            let refsArray = refs.components(separatedBy: "><")
            linkedUids.insert(objectsIn: refsArray)
        }
        if var reply = inReplyTo, !reply.isEmpty {
            reply.removeFirst()
            reply.removeLast()
            reply = reply.replacingOccurrences(of: "> <", with: "><")
            let replyArray = reply.components(separatedBy: "><")
            linkedUids.insert(objectsIn: replyArray)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case uid
        case msgId
        case subject
        case priority
        case date
        case size
        case from
        case to
        case cc
        case bcc
        case replyTo
        case body
        case attachments
        case dkimStatus
        case attachmentsResource
        case resource
        case downloadResource
        case draftResource
        case stUuid
        case folderId
        case folder
        case references
        case inReplyTo
        case preview
        case answered
        case isDuplicate
        case isDraft
        case hasAttachments
        case seen
        case scheduled
        case forwarded
        case flagged
        case safeDisplay
        case hasUnsubscribeLink
    }

    override init() {
        super.init()
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        uid = try values.decode(String.self, forKey: .uid)
        if let msgId = try? values.decode(String.self, forKey: .msgId) {
            self.messageId = msgId
            linkedUids = [msgId].toRealmSet()
        }
        subject = try values.decodeIfPresent(String.self, forKey: .subject)
        priority = try values.decode(MessagePriority.self, forKey: .priority)
        date = try values.decode(Date.self, forKey: .date)
        size = try values.decode(Int.self, forKey: .size)
        from = try values.decode(List<Recipient>.self, forKey: .from)
        to = try values.decode(List<Recipient>.self, forKey: .to)
        cc = try values.decode(List<Recipient>.self, forKey: .cc)
        bcc = try values.decode(List<Recipient>.self, forKey: .bcc)
        replyTo = try values.decode(List<Recipient>.self, forKey: .replyTo)
        body = try values.decodeIfPresent(Body.self, forKey: .body)
        if let attachments = try? values.decode(List<Attachment>.self, forKey: .attachments) {
            self.attachments = attachments
        } else {
            attachments = List()
        }
        dkimStatus = try values.decode(MessageDKIM.self, forKey: .dkimStatus)
        attachmentsResource = try values.decodeIfPresent(String.self, forKey: .attachmentsResource)
        resource = try values.decode(String.self, forKey: .resource)
        downloadResource = try values.decode(String.self, forKey: .downloadResource)
        draftResource = try values.decodeIfPresent(String.self, forKey: .draftResource)
        stUuid = try values.decodeIfPresent(String.self, forKey: .stUuid)
        folderId = try values.decode(String.self, forKey: .folderId)
        folder = try values.decode(String.self, forKey: .folder)
        references = try values.decodeIfPresent(String.self, forKey: .references)
        inReplyTo = try values.decodeIfPresent(String.self, forKey: .inReplyTo)
        preview = try values.decode(String.self, forKey: .preview)
        answered = try values.decode(Bool.self, forKey: .answered)
        isDuplicate = try values.decodeIfPresent(Bool.self, forKey: .isDuplicate)
        isDraft = try values.decode(Bool.self, forKey: .isDraft)
        hasAttachments = try values.decode(Bool.self, forKey: .hasAttachments)
        seen = try values.decode(Bool.self, forKey: .seen)
        scheduled = try values.decode(Bool.self, forKey: .scheduled)
        forwarded = try values.decode(Bool.self, forKey: .forwarded)
        flagged = try values.decode(Bool.self, forKey: .flagged)
        safeDisplay = try values.decodeIfPresent(Bool.self, forKey: .safeDisplay)
        hasUnsubscribeLink = try values.decodeIfPresent(Bool.self, forKey: .hasUnsubscribeLink)
    }

    public convenience init(
        uid: String,
        msgId: String,
        subject: String? = nil,
        priority: MessagePriority,
        date: Date,
        size: Int,
        from: [Recipient],
        to: [Recipient],
        cc: [Recipient],
        bcc: [Recipient],
        replyTo: [Recipient],
        body: Body? = nil,
        attachments: [Attachment],
        dkimStatus: MessageDKIM,
        resource: String,
        downloadResource: String,
        stUuid: String? = nil,
        folderId: String,
        folder: String,
        references: String? = nil,
        preview: String,
        answered: Bool,
        isDuplicate: Bool? = nil,
        isDraft: Bool,
        hasAttachments: Bool,
        seen: Bool,
        scheduled: Bool,
        forwarded: Bool,
        flagged: Bool,
        safeDisplay: Bool? = nil,
        hasUnsubscribeLink: Bool? = nil
    ) {
        self.init()

        self.uid = uid
        self.messageId = msgId
        self.subject = subject
        self.priority = priority
        self.date = date
        self.size = size
        self.from = from.toRealmList()
        self.to = to.toRealmList()
        self.cc = cc.toRealmList()
        self.bcc = bcc.toRealmList()
        self.replyTo = replyTo.toRealmList()
        self.body = body
        self.attachments = attachments.toRealmList()
        self.dkimStatus = dkimStatus
        self.resource = resource
        self.downloadResource = downloadResource
        self.stUuid = stUuid
        self.folderId = folderId
        self.folder = folder
        self.references = references
        self.preview = preview
        self.answered = answered
        self.isDuplicate = isDuplicate
        self.isDraft = isDraft
        self.hasAttachments = hasAttachments
        self.seen = seen
        self.scheduled = scheduled
        self.forwarded = forwarded
        self.flagged = flagged
        self.safeDisplay = safeDisplay
        self.hasUnsubscribeLink = hasUnsubscribeLink
        fullyDownloaded = true
    }

    convenience init(draft: Draft) {
        self.init()

        if let messageUid = draft.messageUid {
            uid = messageUid
        }
        subject = draft.subject
        priority = draft.priority
        date = draft.date
        size = 0
        to = draft.to.detached()
        cc = draft.cc.detached()
        bcc = draft.bcc.detached()
        let messageBody = Body()
        messageBody.value = draft.body
        messageBody.type = draft.mimeType
        body = messageBody
        attachments = draft.attachments.detached()
        references = draft.references
        isDraft = true
    }

    public func toThread() -> Thread {
        let thread = Thread(
            uid: "\(folderId)_\(uid)",
            messagesCount: 1,
            deletedMessagesCount: 1,
            messages: [self],
            unseenMessages: seen ? 0 : 1,
            from: Array(from),
            to: Array(to),
            cc: Array(cc),
            bcc: Array(bcc),
            subject: subject,
            date: date,
            hasAttachments: !attachments.isEmpty,
            hasStAttachments: false,
            hasDrafts: !(draftResource?.isEmpty ?? true),
            flagged: flagged,
            answered: answered,
            forwarded: forwarded,
            size: size,
            folderId: folderId
        )
        thread.messageIds = linkedUids
        return thread
    }
}

// MARK: - Body

public struct BodyResult: Codable {
    let body: Body
}

public class Body: EmbeddedObject, Codable {
    @Persisted public var value: String
    @Persisted public var type: String
    @Persisted public var subBody: String?
}

public struct MessageActionResult: Codable {
    public var flagged: Int
}
