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
import MailCore

/// Something that take care of actions related to a message
protocol MessageActionHandlable {
    /// Present the new mail to the user with the correct account
    func handleTapOnNotification(messageUid: String, mailbox: Mailbox, mailboxManager: MailboxManager) async throws

    /// Silently move mail to `archive` folder
    func handleArchiveOnNotification(messageUid: String, mailboxManager: MailboxManager) async throws

    /// Silently move mail to `trash` folder
    func handleDeleteOnNotification(messageUid: String, mailboxManager: MailboxManager) async throws

    /// Present a new `reply to` draft to the user with the correct account
    func handleReplyOnNotification(messageUid: String, mailbox: Mailbox, mailboxManager: MailboxManager) async
}
