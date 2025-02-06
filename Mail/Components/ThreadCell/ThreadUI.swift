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
import InfomaniakCore
import MailCore
import MailResources

struct ThreadUI: Identifiable, Equatable {
    static let lastMessageNotFromSentPredicate = NSPredicate(
        format: "SUBQUERY(folders, $folder, $folder.role != %@).@count > 0",
        FolderRole.sent.rawValue
    )

    let id: String

    /// Sender of the last message that is not in the Sent folder, otherwise the last message of the thread
    let recipientToDisplay: Recipient?

    /// Subject of the first message
    let subject: String

    let additionalEmail: String?

    /// Last message of the thread, except for the Sent folder where we use the last message of the folder
    let preview: String

    let isInWrittenByMeFolder: Bool

    let recipientsTitle: String
    let messageCount: Int
    let date: Date
    let searchFolderName: String?
    let lastAction: ThreadLastAction?

    let hasUnseenMessages: Bool
    let hasAttachments: Bool
    let hasDrafts: Bool
    let flagged: Bool

    let contactConfiguration: ContactConfiguration

    init(thread: Thread, contextUser: UserProfile, contextMailboxManager: MailboxManager) {
        id = thread.id

        // swiftlint:disable:next last_where
        let lastMessageNotFromSent = thread.messages.filter(Self.lastMessageNotFromSentPredicate).last ?? thread.messages.last

        subject = thread.formattedSubject

        isInWrittenByMeFolder = FolderRole.writtenByMeFolders.contains { $0 == thread.folder?.role }

        let content: String?
        if isInWrittenByMeFolder {
            recipientToDisplay = lastMessageNotFromSent?.to.first
            content = (thread.lastMessageFromFolder ?? thread.messages.last)?.preview
        } else {
            recipientToDisplay = lastMessageNotFromSent?.from.first
            content = thread.messages.last?.preview
        }

        recipientsTitle = thread.formatted(
            contextUser: contextUser,
            contextMailboxManager: contextMailboxManager,
            style: isInWrittenByMeFolder ? .to : .from
        )

        if let content, !content.isEmpty {
            preview = content
        } else {
            preview = MailResourcesStrings.Localizable.noBodyTitle
        }

        messageCount = thread.messages.count
        date = thread.date

        additionalEmail = thread.folder?.role == .spam ? recipientToDisplay?.email : nil
        searchFolderName = thread.searchFolderName

        lastAction = thread.lastAction
        hasUnseenMessages = thread.hasUnseenMessages
        hasAttachments = thread.hasAttachments
        hasDrafts = thread.hasDrafts
        flagged = thread.flagged

        if let recipientToDisplay {
            contactConfiguration = .correspondent(
                correspondent: recipientToDisplay,
                associatedBimi: thread.bimi,
                contextUser: contextUser,
                contextMailboxManager: contextMailboxManager
            )
        } else {
            contactConfiguration = .emptyContact
        }
    }

    func resolveThread(contextMailboxManager: MailboxManager) -> Thread? {
        contextMailboxManager.getThread(from: id)
    }

    static func == (lhs: ThreadUI, rhs: ThreadUI) -> Bool {
        return lhs.id == rhs.id &&
            lhs.recipientToDisplay == rhs.recipientToDisplay &&
            lhs.subject == rhs.subject &&
            lhs.additionalEmail == rhs.additionalEmail &&
            lhs.preview == rhs.preview &&
            lhs.isInWrittenByMeFolder == rhs.isInWrittenByMeFolder &&
            lhs.recipientsTitle == rhs.recipientsTitle &&
            lhs.messageCount == rhs.messageCount &&
            lhs.date == rhs.date &&
            lhs.searchFolderName == rhs.searchFolderName &&
            lhs.lastAction == rhs.lastAction &&
            lhs.hasUnseenMessages == rhs.hasUnseenMessages &&
            lhs.hasAttachments == rhs.hasAttachments &&
            lhs.hasDrafts == rhs.hasDrafts &&
            lhs.flagged == rhs.flagged
    }
}
