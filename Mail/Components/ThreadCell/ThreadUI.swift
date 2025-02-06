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

    /// Last message of the thread, except for the Sent folder where we use the last message of the folder
    let preview: String

    let isInWrittenByMeFolder: Bool

    init(thread: Thread) {
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

        if let content, !content.isEmpty {
            preview = content
        } else {
            preview = MailResourcesStrings.Localizable.noBodyTitle
        }
    }

    func contactConfiguration(bimi: Bimi?, contextUser: UserProfile,
                              contextMailboxManager: MailboxManager) -> ContactConfiguration {
        if let recipientToDisplay {
            return .correspondent(
                correspondent: recipientToDisplay,
                associatedBimi: bimi,
                contextUser: contextUser,
                contextMailboxManager: contextMailboxManager
            )
        } else {
            return .emptyContact
        }
    }
}
