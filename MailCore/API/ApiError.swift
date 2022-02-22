//
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

open class ApiError: Codable, Error {
    public var code: String
    public var description: String
}

enum ApiErrorCode: String {
    // General
    case notAuthorized = "not_authorized"

    // Folder
    case folderUnableToCreate = "folder__unable_to_create"
    case folderUnableToUpdate = "folder__unable_to_update"
    case folderUnableToDelete = "folder__unable_to_delete"
    case folderUnableToFlush = "folder__unable_to_flush"
    case protectedFolder = "folder__protected_folder"
    case folderUnableToMoveInSub = "folder__unable_to_move_folder_in_its_sub_folders"
    case destinationFolderAlreadyExists = "folder__destination_folder_already_exists"
    case rootDestinationNotExists = "folder__root_destination_not_exists"
    case folderAlreadyExists = "folder__destination_already_exists"
    case folderNotExists = "folder__not_exists"

    // Mail
    case moveDestinationNotFound = "mail__move_destination_folder_not_found"
    case cannotConnectToIMAPServer = "mail__cannot_connect_to_server"
    case IMAPAuthFailed = "mail__imap_authentication_failed"
    case IMAPUnableToParseResponse = "mail__imap_unable_to_parse_response"
    case IMAPConnectionTimedOut = "mail__imap_connection_timedout"
    case cannotConnectToSMTPServer = "mail__cannot_connect_to_smtp_server"
    case SMTPAuthFailed = "mail__smtp_authentication_failed"
    case messageNotFound = "mail__message_not_found"
    case messageAttachmentNotFound = "mail__message_attachment_not_found"
    case unableToUndoMoveAction = "mail__unable_to_undo_move_action"
    case unableToMoveEmails = "mail__unable_to_move_emails"

    // Draft
    case draftAttachmentNotFound = "draft__attachment_not_found"
    case draftNotFound = "draft__not_found"
    case draftMessageNotFound = "draft__message_not_found"
    case draftTooManyRecipients = "draft__to_many_recipients"
    case draftMaxAttachmentsSizeReached = "draft__max_attachments_size_reached"
    case draftNeedAtLeastOneRecipient = "draft__need_at_least_one_recipient_to_be_sent"
    case draftAlreadyScheduledOrSent = "draft__cannot_modify_scheduled_or_already_sent_message"
    case draftCannotCancelNonScheduledMessage = "draft__cannot_cancel_non_scheduled_message"
    case draftCannotForwardMoreThanOneMessageInline = "draft__cannot_forward_more_than_one_message_inline"
    case draftCannotMoveScheduledMessage = "draft__cannot_move_scheduled_message"

    // Send
    case sendFromRefused = "send__server_refused_from"
    case sendRecipientRefused = "send__server_refused_all_recipients"
    case sendLimitExceeded = "send__server_rate_limit_exceeded"
    case sendUnknownError = "send__server_unknown_error"
    case sendDailyLimitReached = "send__server_daily_limit_reached"
    case sendSpamRejected = "send__spam_rejected"
    case sendSenderMismatch = "send__sender_mismatch"

    // Attachment
    case attachmentNotValid = "attachment__not_valid"
    case attachmentNotFound = "attachment__not_found"
    case attachmentCannotRender = "attachment__cannot_render"
    case attachmentRenderError = "attachment__error_while_render"
    case attachmentMissingFilenameOrMimeType = "attachment__missing_filename_or_mimetype"
    case attachmentUploadIncorrect = "attachment__incorrect_disposition"
    case attachmentUploadContentIdNotValid = "attachment__content_id_not_valid"
    case attachmentAddFromDriveFailed = "attachment__add_attachment_from_drive_fail"
    case attachmentStoreToDriveFailed = "attachment__store_to_drive_fail"

    // Message
    case messageUidIsNotValid = "message__uid_is_not_valid"

    var localizedDescription: String {
        switch self {
        case .notAuthorized:
            return "Not authorized"
        case .folderUnableToCreate:
            return "Unable to create folder"
        case .folderUnableToUpdate:
            return "Unable to update folder"
        case .folderUnableToDelete:
            return "Unable to delete folder"
        case .folderUnableToFlush:
            return "Unable to flush folder"
        case .protectedFolder:
            return "Protected folder"
        case .folderUnableToMoveInSub:
            return "Unable to move folder in its sub folders"
        case .destinationFolderAlreadyExists:
            return "Destination folder already exists"
        case .rootDestinationNotExists:
            return "Root destination does not exist"
        case .folderAlreadyExists:
            return "Destination already exists"
        case .folderNotExists:
            return "Folder does not exist"
        case .moveDestinationNotFound:
            return "Move destination folder not found"
        case .cannotConnectToIMAPServer:
            return "Cannot connect to IMAP server"
        case .IMAPAuthFailed:
            return "IMAP authentication failed"
        case .IMAPUnableToParseResponse:
            return "Unable to parse IMAP response"
        case .IMAPConnectionTimedOut:
            return "IMAP connection timed out"
        case .cannotConnectToSMTPServer:
            return "Cannot connect to SMTP server"
        case .SMTPAuthFailed:
            return "SMTP authentication failed"
        case .messageNotFound:
            return "Message not found"
        case .messageAttachmentNotFound:
            return "Message attachment not found"
        case .unableToUndoMoveAction:
            return "Unable to undo move action"
        case .unableToMoveEmails:
            return "Unable to move emails"
        case .draftAttachmentNotFound:
            return "Attachment not found"
        case .draftNotFound:
            return "Draft not found"
        case .draftMessageNotFound:
            return "Message not found"
        case .draftTooManyRecipients:
            return "Too many recipients"
        case .draftMaxAttachmentsSizeReached:
            return "Max attachments size reached"
        case .draftNeedAtLeastOneRecipient:
            return "Draft needs at least one recipient to be sent"
        case .draftAlreadyScheduledOrSent:
            return "Cannot modify scheduled or already sent message"
        case .draftCannotCancelNonScheduledMessage:
            return "Cannot cancel non scheduled message"
        case .draftCannotForwardMoreThanOneMessageInline:
            return "Cannot forward more than one message inline"
        case .draftCannotMoveScheduledMessage:
            return "Cannot move scheduled message"
        case .sendFromRefused:
            return "Server refused from"
        case .sendRecipientRefused:
            return "Server refused all recipients"
        case .sendLimitExceeded:
            return "Rate limit exceeded"
        case .sendUnknownError:
            return "Unknown server error"
        case .sendDailyLimitReached:
            return "Daily limit reached"
        case .sendSpamRejected:
            return "Spam rejected"
        case .sendSenderMismatch:
            return "Sender mismatch"
        case .attachmentNotValid:
            return "Attachment not valid"
        case .attachmentNotFound:
            return "Attachment not found"
        case .attachmentCannotRender:
            return "Attachment cannot render"
        case .attachmentRenderError:
            return "Attachment render error"
        case .attachmentMissingFilenameOrMimeType:
            return "Attachment missing filename or mime type"
        case .attachmentUploadIncorrect:
            return "Attachment incorrect disposition"
        case .attachmentUploadContentIdNotValid:
            return "Attachment content ID not valid"
        case .attachmentAddFromDriveFailed:
            return "Add attachment from drive failed"
        case .attachmentStoreToDriveFailed:
            return "Store attachment to drive failed"
        case .messageUidIsNotValid:
            return "Message UID is not valid"
        }
    }
}
