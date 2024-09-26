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
import MailResources
import RealmSwift

public class Attachment: /* Hashable, */ EmbeddedObject, Codable, Identifiable {
    @Persisted public var uuid: String
    @Persisted public var partId: String // PROBLEM: Sometimes API return a String, sometimes an Int. Check with backend if we can have one type only? -- Asked to Julien A. on 08.09 - To follow up.
    @Persisted public var mimeType: String
    @Persisted public var encoding: String?
    @Persisted public var size: Int64
    @Persisted public var name: String
    @Persisted public var disposition: AttachmentDisposition
    @Persisted public var contentId: String?
    @Persisted public var resource: String?
    @Persisted public var driveUrl: String?
    @Persisted(originProperty: "attachments") var parentLink: LinkingObjects<Message>
    @Persisted public var saved = false
    @Persisted public var temporaryLocalUrl: String?

    public var parent: Message? {
        return parentLink.first
    }

    public var icon: MailResourcesImages {
        return AttachmentHelper(type: mimeType).icon
    }

    private enum CodingKeys: String, CodingKey {
        case uuid
        case partId
        case mimeType
        case encoding
        case size
        case name
        case disposition
        case contentId
        case resource
        case driveUrl
    }

    public static func == (lhs: Attachment, rhs: Attachment) -> Bool {
        return lhs.id == rhs.id
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try values.decodeIfPresent(String.self, forKey: .uuid) ?? ""
        if let partId = try? values.decode(Int.self, forKey: .partId) {
            self.partId = "\(partId)"
        } else {
            partId = try values.decodeIfPresent(String.self, forKey: .partId) ?? ""
        }
        mimeType = try values.decode(String.self, forKey: .mimeType)
        encoding = try values.decodeIfPresent(String.self, forKey: .encoding)
        size = try values.decode(Int64.self, forKey: .size)
        name = try values.decode(String.self, forKey: .name)
        disposition = try values.decode(AttachmentDisposition.self, forKey: .disposition)
        contentId = try values.decodeIfPresent(String.self, forKey: .contentId)
        resource = try values.decodeIfPresent(String.self, forKey: .resource)
        driveUrl = try values.decodeIfPresent(String.self, forKey: .driveUrl)
    }

    override init() {
        super.init()
    }

    public convenience init(
        uuid: String = "",
        partId: String,
        mimeType: String,
        encoding: String? = nil,
        size: Int64,
        name: String,
        disposition: AttachmentDisposition,
        contentId: String? = nil,
        resource: String? = nil,
        driveUrl: String? = nil
    ) {
        self.init()

        self.uuid = uuid
        self.partId = partId
        self.mimeType = mimeType
        self.encoding = encoding
        self.size = size
        self.name = name
        self.disposition = disposition
        self.contentId = contentId
        self.resource = resource
        self.driveUrl = driveUrl
    }

    public func getLocalURL(userId: Int, mailboxId: Int) -> URL {
        var localURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(userId)/\(mailboxId)")
        if let folderId = parent?.folderId {
            localURL = localURL.appendingPathComponent("\(folderId)")
        }
        if let shortUid = parent?.shortUid {
            localURL = localURL.appendingPathComponent("\(shortUid)")
        }

        return localURL.appendingPathComponent("\(partId)/\(name)")
    }

    public func getLocalURL(mailboxManager: MailboxManager) -> URL {
        getLocalURL(userId: mailboxManager.mailbox.userId, mailboxId: mailboxManager.mailbox.mailboxId)
    }

    public func update(with remoteAttachment: Attachment) {
        uuid = remoteAttachment.uuid
        partId = remoteAttachment.partId
        mimeType = remoteAttachment.mimeType
        size = remoteAttachment.size
        name = remoteAttachment.name
        disposition = remoteAttachment.disposition
        contentId = remoteAttachment.contentId
        resource = remoteAttachment.resource
        driveUrl = remoteAttachment.driveUrl
        temporaryLocalUrl = remoteAttachment.temporaryLocalUrl
    }
}

public enum AttachmentDisposition: String, Codable, PersistableEnum {
    case inline, attachment

    public static let defaultDisposition = AttachmentDisposition.attachment
}
