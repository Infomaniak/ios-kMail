/*
 Infomaniak Mail - iOS App
 Copyright (C) 2026 Infomaniak Network SA

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
import MailCore
import MailResources

public struct UIAttachment: Equatable, Hashable, Identifiable, Sendable {
    public enum ID: Hashable, Sendable {
        case draftAttachment(draftLocalUUID: String, objectId: UInt64)
        case messageAttachment(messageUid: String, objectId: UInt64)
        case swissTransfer(transferId: String, fileId: String)
    }

    public let id: ID
    public let uuid: String
    public let name: String
    public let size: Int64
    public let mimeType: String
    public let isInline: Bool
    public let isWalletPass: Bool
    public let localURL: URL?
    public let temporaryLocalURL: URL?

    public var icon: MailResourcesImages {
        switch id {
        case .draftAttachment, .messageAttachment:
            let fileExtension = URL(filePath: name).pathExtension
            return AttachmentHelper(type: mimeType, fileExtension: fileExtension).icon
        case .swissTransfer:
            return AttachmentHelper(type: mimeType, fileExtension: nil).icon
        }
    }

    public var availableLocalURL: URL? {
        return [localURL, temporaryLocalURL].compactMap { $0 }.first {
            FileManager.default.fileExists(atPath: $0.path)
        }
    }

    public init(attachment: Attachment, draftLocalUUID: String, localURL: URL) {
        self.init(attachment: attachment, id: Self.id(for: attachment, draftLocalUUID: draftLocalUUID), localURL: localURL)
    }

    public init(attachment: Attachment, messageUid: String, localURL: URL) {
        self.init(attachment: attachment, id: Self.id(for: attachment, messageUid: messageUid), localURL: localURL)
    }

    public init(swissTransferFile: File, transferId: String) {
        id = .swissTransfer(transferId: transferId, fileId: swissTransferFile.uuid)
        uuid = swissTransferFile.uuid
        name = swissTransferFile.name
        size = Int64(swissTransferFile.size)
        mimeType = swissTransferFile.type
        isInline = false
        isWalletPass = false
        localURL = nil
        temporaryLocalURL = nil
    }

    private init(attachment: Attachment, id: ID, localURL: URL) {
        self.id = id
        uuid = attachment.uuid
        name = attachment.name
        size = attachment.size
        mimeType = attachment.mimeType
        isInline = attachment.isInline
        isWalletPass = attachment.isWalletPass
        self.localURL = localURL
        if let rawTemporaryLocalURL = attachment.temporaryLocalUrl {
            temporaryLocalURL = URL(fileURLWithPath: rawTemporaryLocalURL)
        } else {
            temporaryLocalURL = nil
        }
    }

    public static func id(for attachment: Attachment, draftLocalUUID: String) -> ID {
        return .draftAttachment(draftLocalUUID: draftLocalUUID, objectId: attachment.id)
    }

    public static func id(for attachment: Attachment, messageUid: String) -> ID {
        return .messageAttachment(messageUid: messageUid, objectId: attachment.id)
    }
}
