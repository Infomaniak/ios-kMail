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

import Foundation
import InfomaniakCoreDB
import RealmSwift

/// An abstract interface on the `MailboxManager`
public typealias MailboxManageable = MailboxManagerAttachable
    & MailboxManagerCalendareable
    & MailboxManagerContactable
    & MailboxManagerDraftable
    & MailboxManagerFolderable
    & MailboxManagerMailboxable
    & MailboxManagerMessageable
    & MailboxManagerSearchable
    & RealmConfigurable
    & Transactionable

public protocol MailboxManagerMailboxable {
    var mailbox: Mailbox { get }
}

/// An abstract interface on the `MailboxManager` related to messages
public protocol MailboxManagerMessageable {
    func messages(folder: Folder) async throws
    func fetchOneNewPage(folder: Folder) async throws -> Bool
    func fetchOneOldPage(folder: Folder) async throws -> Int?
    func message(message: Message) async throws
    func attachmentData(_ attachment: Attachment, progressObserver: ((Double) -> Void)?) async throws -> Data
    func saveAttachmentLocally(attachment: Attachment, progressObserver: ((Double) -> Void)?) async
    func markAsSeen(message: Message, seen: Bool) async throws
    func move(messages: [Message], to folderRole: FolderRole, origin: Folder?) async throws -> UndoAction
    func move(messages: [Message], to folder: Folder, origin: Folder?) async throws -> UndoAction
    func delete(messages: [Message]) async throws
}

/// An abstract interface on the `MailboxManager` related to drafts
public protocol MailboxManagerDraftable {
    func draftWithPendingAction() -> Results<Draft>
    func draft(messageUid: String) -> Draft?
    func draft(messageUid: String, using realm: Realm) -> Draft?
    func draft(localUuid: String) -> Draft?
    func draft(localUuid: String, using realm: Realm) -> Draft?
    func draft(remoteUuid: String) -> Draft?
    func draft(remoteUuid: String, using realm: Realm) -> Draft?
    func send(draft: Draft) async throws -> SendResponse
    func save(draft: Draft) async throws
    func delete(draft: Draft) async throws
    func delete(draftMessage: Message) async throws
    func deleteLocally(draft: Draft) async throws
    func deleteOrphanDrafts() async
}

/// An abstract interface on the `MailboxManager` related to Folders
public protocol MailboxManagerFolderable {
    func refreshAllFolders() async throws
    func getFolder(with role: FolderRole) -> Folder?
    func getFrozenFolders() -> [Folder]
    func createFolder(name: String, parent: Folder?) async throws -> Folder
    func deleteFolder(name: String, folder: Folder) async throws
    func flushFolder(folder: Folder) async throws -> Bool
    func refreshFolder(from messages: [Message], additionalFolder: Folder?) async throws
    func refreshFolderContent(_ folder: Folder) async
    func cancelRefresh() async
}

/// An abstract interface on the `MailboxManager` related to search
public protocol MailboxManagerSearchable {
    func initSearchFolder() -> Folder
    func clearSearchResults() async
    func searchThreads(searchFolder: Folder?, filterFolderId: String, filter: Filter,
                       searchFilter: [URLQueryItem]) async throws -> ThreadResult
    func searchThreads(searchFolder: Folder?, from resource: String,
                       searchFilter: [URLQueryItem]) async throws -> ThreadResult
    func searchThreadsOffline(searchFolder: Folder?, filterFolderId: String,
                              searchFilters: [SearchCondition]) async
    func addToSearchHistory(value: String) async
}

/// An abstract interface on the `MailboxManager` related to contacts
public protocol MailboxManagerContactable {
    var contactManager: ContactManageable { get }
}

public protocol MailboxManagerCalendareable {
    func calendarEvent(from messageUid: String) async throws
    func replyToCalendarEvent(messageUid: String, reply: AttendeeState) async throws
    func importICSEventToCalendar(messageUid: String) async throws -> CalendarEvent
}

public protocol MailboxManagerAttachable {
    func swissTransferAttachment(message: Message) async throws
}

// TODO: write a dedicated protocol for each MailboxManager
