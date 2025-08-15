/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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

public enum EmojiReactionNotAllowedReason: String, Decodable, PersistableEnum {
    case folderNotAllowedDraft = "folder_not_allowed_draft"
    case folderNotAllowedScheduledDraft = "folder_not_allowed_scheduled_draft"
    case folderNotAllowedSpam = "folder_not_allowed_spam"
    case folderNotAllowedTrash = "folder_not_allowed_trash"

    case messageInReplyToNotValid = "message_in_reply_to_not_valid"
    case messageInReplyToNotAllowed = "message_in_reply_to_not_allowed"
    case messageInReplyToEncrypted = "message_in_reply_to_encrypted"

    case tooManyRecipients = "max_recipient"
    case recipientNotAllowed = "recipient_not_allowed"

    case unknown

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawString = try container.decode(String.self)

        self = EmojiReactionNotAllowedReason(rawValue: rawString) ?? .unknown
    }

    public var localizedDescription: String {
        guard let message = associatedError?.errorDescription else {
            return MailResourcesStrings.Localizable.errorUnknown
        }
        return message
    }

    private var associatedError: MailApiError? {
        switch self {
        case .folderNotAllowedDraft:
            return .emojiReactionFolderNotAllowedDraft
        case .folderNotAllowedScheduledDraft:
            return .emojiReactionFolderNotAllowedScheduledDraft
        case .folderNotAllowedSpam:
            return .emojiReactionFolderNotAllowedSpam
        case .folderNotAllowedTrash:
            return .emojiReactionFolderNotAllowedTrash
        case .messageInReplyToNotValid:
            return .emojiReactionMessageInReplyToNotValid
        case .messageInReplyToNotAllowed:
            return .emojiReactionMessageInReplyToNotAllowed
        case .messageInReplyToEncrypted:
            return .emojiReactionMessageInReplyToEncrypted
        case .tooManyRecipients:
            return .emojiReactionMaxRecipient
        case .recipientNotAllowed:
            return .emojiReactionRecipientNotAllowed
        case .unknown:
            return nil
        }
    }
}
