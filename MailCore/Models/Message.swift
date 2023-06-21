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
import InfomaniakCore
import MailResources
import RealmSwift
import Sentry

// TODO: move to core
public extension String {
    /// Max length of a string before we need to truncate it.
    static let closeToMaxRealmSize = 14_000_000

    /// Truncate a string for compatibility with Realm if needed
    ///
    /// The string will be terminated by " [truncated]" if it was
    var truncatedForRealmIfNeeded: Self {
        Self.truncatedForRealmIfNeeded(self)
    }

    /// Truncate a string for compatibility with Realm if needed
    ///
    /// The string will be terminated by " [truncated]" if it was
    /// - Parameter input: an input string
    /// - Returns: The output string truncated if needed
    static func truncatedForRealmIfNeeded(_ input: String) -> String {
        if input.utf8.count > Self.closeToMaxRealmSize {
            let index = input.index(input.startIndex, offsetBy: Self.closeToMaxRealmSize)
            let truncatedValue = String(input[...index]) + " [truncated]"
            return truncatedValue
        } else {
            return input
        }
    }
}

public enum NewMessagesDirection: String {
    case previous
    case following
}

public struct PaginationInfo {
    let offsetUid: String
    let direction: NewMessagesDirection
}

public final class MessageUidsResult: Decodable {
    public let messageShortUids: [String]
    public let cursor: String

    private enum CodingKeys: String, CodingKey {
        case messageShortUids = "messagesUids"
        case cursor = "signature"
    }
}

public final class MessageByUidsResult: Decodable {
    public let messages: [Message]
}

public final class MessageDeltaResult: Decodable {
    public let deletedShortUids: [String]
    public let addedShortUids: [String]
    public let updated: [MessageFlags]
    public let cursor: String

    private enum CodingKeys: String, CodingKey {
        case deletedShortUids = "deleted"
        case addedShortUids = "added"
        case updated
        case cursor = "signature"
    }

    // FIXME: Remove this constructor when mixed Int/String arrayis fixed by backend
    public required init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)

        if let deletedShortUids = try? container.decode([String].self, forKey: .deletedShortUids) {
            self.deletedShortUids = deletedShortUids
        } else {
            deletedShortUids = try container.decode([Int].self, forKey: .deletedShortUids).map { "\($0)" }
        }
        if let addedShortUids = try? container.decode([String].self, forKey: .addedShortUids) {
            self.addedShortUids = addedShortUids
        } else {
            addedShortUids = try container.decode([Int].self, forKey: .addedShortUids).map { "\($0)" }
        }
        updated = try container.decode([MessageFlags].self, forKey: .updated)
        cursor = try container.decode(String.self, forKey: .cursor)
    }
}

public struct MessagesUids {
    public let addedShortUids: [String]
    public var deletedUids = [String]()
    public var updated = [MessageFlags]()
    public let cursor: String
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

public extension Array where Element: Message {
    func isLast(_ message: Message) -> Bool {
        last?.uid == message.uid
    }

    func isExpanded(_ message: Message) -> Bool {
        (isLast(message) && !message.isDraft) || !message.seen
    }
}

public final class Message: Object, Decodable, Identifiable {
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
    @Persisted public var attachmentsResources: String?
    @Persisted public var resource: String
    @Persisted public var downloadResource: String
    @Persisted public var draftResource: String?
    @Persisted public var swissTransferUuid: String?
    @Persisted public var folderId: String
    @Persisted public var references: String?
    @Persisted public var inReplyTo: String?
    @Persisted public var linkedUids: MutableSet<String>
    @Persisted public var preview: String
    @Persisted public var answered: Bool
    @Persisted public var isDraft: Bool
    @Persisted public var hasAttachments: Bool
    @Persisted public var seen: Bool
    @Persisted public var scheduled: Bool
    @Persisted public var forwarded: Bool
    @Persisted public var flagged: Bool
    @Persisted private var safeDisplay: Bool?
    @Persisted public var hasUnsubscribeLink: Bool?
    @Persisted(originProperty: "messages") var threads: LinkingObjects<Thread>
    @Persisted(originProperty: "messages") private var folders: LinkingObjects<Folder>
    @Persisted(originProperty: "duplicates") var threadsDuplicatedIn: LinkingObjects<Thread>

    @Persisted public var fullyDownloaded = false
    @Persisted public var fromSearch = false
    @Persisted public var inTrash = false
    @Persisted public var localSafeDisplay = false

    public var shortUid: Int? {
        return Int(Constants.shortUid(from: uid))
    }

    public var recipients: [Recipient] {
        return Array(to) + Array(cc)
    }

    public var originalThread: Thread? {
        return threads.first { $0.folder?.id == folderId }
    }

    public var folder: Folder? {
        return folders.first
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

    public var duplicates: [Message] {
        guard let dup = originalThread?.duplicates.where({ $0.messageId == messageId }) else { return [] }
        return Array(dup)
    }

    public var fromMe: Bool {
        return from.contains { $0.isMe }
    }

    public var canReplyAll: Bool {
        let holder = recipientsForReplyTo(replyAll: true)
        return !holder.cc.isEmpty
    }

    public func recipientsForReplyTo(replyAll: Bool = false) -> RecipientHolder {
        let cleanedFrom = Array(from.detached()).filter { !$0.isMe }
        let cleanedTo = Array(to.detached()).filter { !$0.isMe }
        let cleanedReplyTo = Array(replyTo.detached()).filter { !$0.isMe }
        let cleanedCc = Array(cc.detached()).filter { !$0.isMe }

        var holder = RecipientHolder()

        let possibleRecipients: [(recipients: [Recipient], forCc: Bool)] = [
            (recipients: cleanedReplyTo, forCc: false),
            (recipients: cleanedFrom, forCc: false),
            (recipients: cleanedTo, forCc: true),
            (recipients: cleanedCc, forCc: true),
            (recipients: from.detached().toArray(), forCc: false)
        ]

        for value in possibleRecipients {
            if holder.to.isEmpty {
                holder.to = value.recipients
            } else if replyAll && value.forCc {
                holder.cc.append(contentsOf: value.recipients)
            }
        }

        return holder
    }

    public func computeReference() {
        if let references {
            linkedUids.insert(objectsIn: references.parseMessageIds())
        }
        if let inReplyTo {
            linkedUids.insert(objectsIn: inReplyTo.parseMessageIds())
        }
    }

    private enum CodingKeys: String, CodingKey {
        case uid
        case messageId = "msgId"
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
        case attachmentsResources
        case resource
        case downloadResource
        case draftResource
        case swissTransferUuid = "stUuid"
        case folderId
        case references
        case inReplyTo
        case preview
        case answered
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
        let uid = try values.decode(String.self, forKey: .uid)
        self.uid = uid
        if let msgId = try? values.decode(String.self, forKey: .messageId) {
            messageId = msgId
            linkedUids = [msgId].toRealmSet()
        }
        subject = try values.decodeIfPresent(String.self, forKey: .subject)
        priority = try values.decode(MessagePriority.self, forKey: .priority)
        if let date = (try? values.decode(Date.self, forKey: .date)) {
            self.date = date
        } else {
            // FIXME: Remove after thread date bug fix
            date = SentryDebug.knownDebugDate
            SentrySDK
                .addBreadcrumb(SentryDebug.createBreadcrumb(
                    level: .warning,
                    category: "Thread algo",
                    message: "Nil message date decoded",
                    data: ["uid": uid]
                ))
        }
        size = try values.decode(Int.self, forKey: .size)
        from = try values.decode(List<Recipient>.self, forKey: .from)
        to = try values.decode(List<Recipient>.self, forKey: .to)
        cc = try values.decode(List<Recipient>.self, forKey: .cc)
        bcc = try values.decode(List<Recipient>.self, forKey: .bcc)
        replyTo = try values.decode(List<Recipient>.self, forKey: .replyTo)

        /// Preprocessing body with a ProxyBody
        let jsonBody = try values.decodeIfPresent(ProxyBody.self, forKey: .body)
        body = jsonBody?.realmObject()

        if let attachments = try? values.decode(List<Attachment>.self, forKey: .attachments) {
            self.attachments = attachments
        } else {
            attachments = List()
        }
        dkimStatus = try values.decode(MessageDKIM.self, forKey: .dkimStatus)
        attachmentsResources = try values.decodeIfPresent(String.self, forKey: .attachmentsResources)
        resource = try values.decode(String.self, forKey: .resource)
        downloadResource = try values.decode(String.self, forKey: .downloadResource)
        draftResource = try values.decodeIfPresent(String.self, forKey: .draftResource)
        swissTransferUuid = try values.decodeIfPresent(String.self, forKey: .swissTransferUuid)
        folderId = try values.decode(String.self, forKey: .folderId)
        references = try values.decodeIfPresent(String.self, forKey: .references)
        inReplyTo = try values.decodeIfPresent(String.self, forKey: .inReplyTo)
        preview = try values.decode(String.self, forKey: .preview)
        answered = try values.decode(Bool.self, forKey: .answered)
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
        swissTransferUuid: String? = nil,
        folderId: String,
        references: String? = nil,
        preview: String,
        answered: Bool,
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
        messageId = msgId
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
        self.swissTransferUuid = swissTransferUuid
        self.folderId = folderId
        self.references = references
        self.preview = preview
        self.answered = answered
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
            hasSwissTransferAttachments: false,
            hasDrafts: !(draftResource?.isEmpty ?? true),
            flagged: flagged,
            answered: answered,
            forwarded: forwarded,
            size: size
        )
        thread.messageIds = linkedUids
        return thread
    }
}

// MARK: - Body

public struct BodyResult: Codable {
    let body: Body
}

/// Proxy class to preprocess JSON of a Body object
/// Preprocessing body to remain within Realm limitations
final class ProxyBody: Codable {
    public var value: String?
    public var type: String?
    public var subBody: String?

    /// Generate a new persisted realm object on the fly
    public func realmObject() -> Body {
        // truncate message if needed
        let truncatedValue = value?.truncatedForRealmIfNeeded

        let body = Body()
        body.value = truncatedValue
        body.type = type
        body.subBody = subBody
        return body
    }
}

public final class Body: EmbeddedObject, Codable {
    /// Public facing "value", wrapping `valueData`
    public var value: String? {
        get {
            guard let decompressedString = valueData?.decompressedString() else {
                return nil
            }

            return decompressedString
        } set {
            guard let data = newValue?.compressed() else {
                valueData = nil
                return
            }

            valueData = data
        }
    }

    @Persisted public var type: String?
    @Persisted public var subBody: String?

    /// Store compressed data to reduce realm size.
    @Persisted var valueData: Data?
}

public struct MessageActionResult: Codable {
    public var flagged: Int
}

public struct PresentableBody: Equatable {
    public var body: Body?

    public var compactBody: String?
    public var quote: String?

    public init(message: Message) {
        body = message.body
    }
}
