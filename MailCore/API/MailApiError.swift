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

/// Static definitions of Mail API error codes
enum MailApiErrorCode {
    /// The email is not found
    static let mailMessageNotFound = "mail__message_not_found"

    /// Invalid credentials
    static let invalidCredentials = "invalid_credentials"

    /// The server does not know about the identity used in the request
    static let identityNotFound = "identity__not_found"
}

public class MailApiError: MailError {
    /// The email is not found
    public static let apiMessageNotFound = MailApiError(code: MailApiErrorCode.mailMessageNotFound,
                                                        localizedDescription: MailResourcesStrings.Localizable
                                                            .errorMessageNotFound,
                                                        shouldDisplay: true)

    /// Invalid credentials
    public static let apiInvalidCredential = MailApiError(code: MailApiErrorCode.invalidCredentials)

    /// The server does not know bout the identity used in the request
    public static let apiIdentityNotFound = MailApiError(code: MailApiErrorCode.identityNotFound, shouldDisplay: false)

    static let allErrors: [MailApiError] = [
        // General
        MailApiError(code: "not_authorized"),
        apiInvalidCredential,

        // Folder
        MailApiError(code: "folder__unable_to_create"),
        MailApiError(code: "folder__unable_to_update"),
        MailApiError(code: "folder__unable_to_delete"),
        MailApiError(code: "folder__unable_to_flush"),
        MailApiError(code: "folder__protected_folder"),
        MailApiError(code: "folder__unable_to_move_folder_in_its_sub_folders"),
        MailApiError(code: "folder__destination_folder_already_exists"),
        MailApiError(code: "folder__root_destination_not_exists"),
        MailApiError(
            code: "folder__destination_already_exists",
            localizedDescription: MailResourcesStrings.Localizable.errorNewFolderAlreadyExists,
            shouldDisplay: true
        ),
        MailApiError(code: "folder__not_exists",
                     localizedDescription: MailResourcesStrings.Localizable.errorFolderNotFound,
                     shouldDisplay: true),

        // Mail
        MailApiError(code: "mail__move_destination_folder_not_found"),
        MailApiError(code: "mail__cannot_connect_to_server"),
        MailApiError(code: "mail__imap_authentication_failed"),
        MailApiError(code: "mail__imap_unable_to_parse_response"),
        MailApiError(code: "mail__imap_connection_timedout"),
        MailApiError(code: "mail__cannot_connect_to_smtp_server"),
        MailApiError(code: "mail__smtp_authentication_failed"),
        apiMessageNotFound,
        MailApiError(code: "mail__message_attachment_not_found"),
        MailApiError(code: "mail__unable_to_undo_move_action"),
        MailApiError(code: "mail__unable_to_move_emails"),

        // Draft
        MailApiError(code: "draft__attachment_not_found"),
        MailApiError(code: "draft__not_found"),
        MailApiError(code: "draft__message_not_found"),
        MailApiError(
            code: "draft__to_many_recipients",
            localizedDescription: MailResourcesStrings.Localizable.tooManyRecipients,
            shouldDisplay: true
        ),
        MailApiError(code: "draft__max_attachments_size_reached"),
        MailApiError(
            code: "draft__need_at_least_one_recipient_to_be_sent",
            localizedDescription: MailResourcesStrings.Localizable.errorAtLeastOneRecipient,
            shouldDisplay: true
        ),
        MailApiError(
            code: "draft__cannot_modify_scheduled_or_already_sent_message",
            localizedDescription: MailResourcesStrings.Localizable.errorEditScheduledMessage,
            shouldDisplay: true
        ),
        MailApiError(code: "draft__cannot_cancel_non_scheduled_message"),
        MailApiError(code: "draft__cannot_forward_more_than_one_message_inline"),
        MailApiError(code: "draft__cannot_move_scheduled_message"),

        // Send
        MailApiError(code: "send__server_refused_from"),
        MailApiError(code: "send__server_refused_all_recipients",
                     localizedDescription: MailResourcesStrings.Localizable.errorRefusedRecipients,
                     shouldDisplay: true),
        MailApiError(code: "send__server_rate_limit_exceeded",
                     localizedDescription: MailResourcesStrings.Localizable.errorSendLimitExceeded,
                     shouldDisplay: true),
        MailApiError(code: "send__server_unknown_error"),
        MailApiError(code: "send__server_daily_limit_reached"),
        MailApiError(code: "send__spam_rejected"),
        MailApiError(code: "send__sender_mismatch"),

        // Attachment
        MailApiError(code: "attachment__not_valid"),
        MailApiError(code: "attachment__not_found"),
        MailApiError(code: "attachment__cannot_render"),
        MailApiError(code: "attachment__error_while_render"),
        MailApiError(code: "attachment__missing_filename_or_mimetype"),
        MailApiError(code: "attachment__incorrect_disposition"),
        MailApiError(code: "attachment__content_id_not_valid"),
        MailApiError(code: "attachment__add_attachment_from_drive_fail"),
        MailApiError(code: "attachment__store_to_drive_fail"),

        // Message
        MailApiError(code: "message__uid_is_not_valid"),

        // Signatures / Identity
        apiIdentityNotFound
    ]

    static func mailApiErrorFromCode(_ code: String) -> MailApiError? {
        return allErrors.first { $0.code == code }
    }

    static func mailApiErrorWithFallback(apiErrorCode: String) -> MailError {
        return mailApiErrorFromCode(apiErrorCode) ?? MailError.unknownError
    }
}
