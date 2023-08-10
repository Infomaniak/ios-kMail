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
import RealmSwift

/// An abstract interface on the `MailboxManager`
public typealias MailboxManageable = MailBoxManagerMessageable & MailBoxManagerDraftable

/// An abstract interface on the `MailboxManager` related to messages
public protocol MailBoxManagerMessageable {
    func messages(folder: Folder) async throws
    func fetchOnePage(folder: Folder, direction: NewMessagesDirection?) async throws -> Bool
    func message(message: Message) async throws
    func attachmentData(attachment: Attachment) async throws -> Data
    func saveAttachmentLocally(attachment: Attachment) async
    func moveOrDelete(messages: [Message]) async throws
    func markAsSeen(message: Message, seen: Bool) async throws
    func move(messages: [Message], to folderRole: FolderRole) async throws -> UndoRedoAction
    func move(messages: [Message], to folder: Folder) async throws -> UndoRedoAction
    func delete(messages: [Message]) async throws
    func toggleStar(messages: [Message]) async throws
}

/// An abstract interface on the `MailboxManager` related to drafts
public protocol MailBoxManagerDraftable {
    func draftWithPendingAction() -> Results<Draft>
    func draft(messageUid: String, using realm: Realm?) -> Draft?
    func draft(localUuid: String, using realm: Realm?) -> Draft?
    func draft(remoteUuid: String, using realm: Realm?) -> Draft?
    func send(draft: Draft) async throws -> SendResponse
    func save(draft: Draft) async throws
    func delete(draft: Draft) async throws
    func delete(draftMessage: Message) async throws
    func deleteLocally(draft: Draft) async throws
    func deleteOrphanDrafts() async
}

// TODO write a dedicated protocol for each MailboxManager+<>
