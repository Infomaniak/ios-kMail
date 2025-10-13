/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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

import Alamofire
import Foundation
import InfomaniakCore

/// Public interface of `MailApiFetcher`
public typealias MailApiFetchable = MailApiAIFetchable & MailApiCalendarFetchable & MailApiCommonFetchable &
    MailApiExtendedFetchable & MailApiSnoozeFetchable & MailApiSyncProfileFetchable

/// Main interface of the `MailApiFetcher`
public protocol MailApiCommonFetchable {
    func mailboxes() async throws -> [Mailbox]

    func listBackups(mailbox: Mailbox) async throws -> BackupsList

    func restoreBackup(mailbox: Mailbox, date: String) async throws -> Bool

    func threads(mailbox: Mailbox,
                 folderId: String,
                 filter: Filter,
                 searchFilter: [URLQueryItem],
                 isDraftFolder: Bool) async throws -> ThreadResult

    func threads(from resource: String, searchFilter: [URLQueryItem]) async throws -> ThreadResult

    func download(messages: [Message]) async throws -> [URL]

    func quotas(mailbox: Mailbox) async throws -> Quotas

    func externalMailFlag(mailbox: Mailbox) async throws -> ExternalMailInfo

    func undoAction(resource: String) async throws -> Bool

    func star(mailbox: Mailbox, messages: [Message]) async throws -> MessageActionResult

    func unstar(mailbox: Mailbox, messages: [Message]) async throws -> MessageActionResult

    func downloadAttachments(message: Message, progressObserver: ((Double) -> Void)?) async throws -> URL

    func blockSender(message: Message) async throws -> NullableResponse

    func reportPhishing(message: Message) async throws -> Bool

    func create(mailbox: Mailbox, folder: NewFolder) async throws -> Folder

    @discardableResult
    func delete(mailbox: Mailbox, folder: Folder) async throws -> Empty?

    func modify(mailbox: Mailbox, folder: Folder, name: String) async throws -> Folder

    func createAttachment(mailbox: Mailbox,
                          attachmentData: Data,
                          attachment: Attachment,
                          progressObserver: @escaping (Double) -> Void) async throws -> Attachment

    func attachmentsToForward(mailbox: Mailbox, message: Message) async throws -> AttachmentsToForwardResult
}

/// Extended capabilities of the `MailApiFetcher`
public protocol MailApiExtendedFetchable {
    func permissions(mailbox: Mailbox) async throws -> MailboxPermissions

    func sendersRestrictions(mailbox: Mailbox) async throws -> SendersRestrictions

    /// Get feature flags for a specific mailbox uuid
    func featureFlag(_ mailboxUUID: String) async throws -> [FeatureFlag]

    /// All the remote contacts
    func contacts() async throws -> [InfomaniakContact]

    func addressBooks() async throws -> AddressBookResult

    func addContact(_ recipient: Recipient, to addressBook: AddressBook) async throws -> Int

    func signatures(mailbox: Mailbox) async throws -> SignatureResponse

    func updateSignature(mailbox: Mailbox, signature: Signature?) async throws -> Bool

    func folders(mailbox: Mailbox) async throws -> [Folder]

    func flushFolder(mailbox: Mailbox, folderId: String) async throws -> Bool

    func messagesUids(mailboxUuid: String, folderId: String) async throws -> MessageUidsResult

    func messagesByUids(mailboxUuid: String, folderId: String, messageUids: [String]) async throws -> MessageByUidsResult

    func messagesDelta<Flags: DeltaFlags>(
        mailboxUuid: String,
        folderId: String,
        signature: String
    ) async throws -> MessagesDelta<Flags>

    func message(message: Message) async throws -> Message

    func markAsSeen(mailbox: Mailbox, messages: [Message]) async throws -> MessageActionResult

    func markAsUnseen(mailbox: Mailbox, messages: [Message]) async throws -> MessageActionResult

    func move(mailboxUuid: String, messages: [Message], destinationId: String, alsoMoveReactions: Bool) async throws
        -> UndoResponse

    func delete(mailbox: Mailbox, messages: [Message], alsoMoveReactions: Bool) async throws -> [Empty]

    func attachment(attachment: Attachment, progressObserver: ((Double) -> Void)?) async throws -> Data

    func draft(mailbox: Mailbox, draftUuid: String) async throws -> Draft

    func draft(from message: Message) async throws -> Draft

    func send<T: Decodable>(mailbox: Mailbox, draft: Draft) async throws -> T

    func deleteDraft(mailbox: Mailbox, draftId: String) async throws -> Empty?

    func deleteDraft(draftResource: String) async throws -> Empty?
}

public protocol MailApiAIFetchable {
    func aiCreateConversation(messages: [AIMessage], output: AIOutputFormat, mailbox: Mailbox) async throws
        -> AIConversationResponse

    func aiShortcut(contextId: String, shortcut: AIShortcutAction, mailbox: Mailbox) async throws
        -> AIShortcutResponse

    func aiShortcutAndRecreateConversation(
        shortcut: AIShortcutAction,
        messages: [AIMessage],
        output: AIOutputFormat,
        mailbox: Mailbox
    ) async throws
        -> AIShortcutResponse
}

public protocol MailApiSyncProfileFetchable {
    func downloadSyncProfile(syncContacts: Bool, syncCalendar: Bool) async throws -> URL

    func applicationPassword() async throws -> ApplicationPassword
}

public protocol MailApiCalendarFetchable {
    func calendarEvent(from attachment: Attachment) async throws -> CalendarEventResponse

    func replyToCalendarEvent(attachment: Attachment, reply: AttendeeState) async throws -> CalendarUpdatedEventResponse

    func replyToCalendarEventAndUpdateCalendar(event: CalendarEvent, reply: AttendeeState) async throws -> Bool

    func importICSEventToCalendar(attachment: Attachment) async throws -> CalendarUpdatedEventResponse
}

public protocol MailApiSnoozeFetchable {
    func snooze(messages: [Message], until date: Date, mailbox: Mailbox) async throws -> [SnoozeAPIResponse]

    func updateSnooze(messages: [Message], until date: Date, mailbox: Mailbox) async throws -> [SnoozeUpdatedAPIResponse]

    func deleteSnooze(messages: [Message], mailbox: Mailbox) async throws -> [SnoozeCancelledAPIResponse]
}
