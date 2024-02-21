/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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
import MailCore

// Stub for extension mode
public struct MessageActionHandler: MessageActionHandlable {
    func handleTapOnNotification(messageUid: String, mailbox: Mailbox, mailboxManager: MailboxManager) async throws {
        // META: Keep SonarCloud happy
    }

    func handleArchiveOnNotification(messageUid: String, mailbox: Mailbox, mailboxManager: MailboxManager) async throws {
        // META: Keep SonarCloud happy
    }

    func handleDeleteOnNotification(messageUid: String, mailbox: Mailbox, mailboxManager: MailboxManager) async throws {
        // META: Keep SonarCloud happy
    }

    func handleReplyOnNotification(messageUid: String, mailbox: Mailbox, mailboxManager: MailboxManager) {
        // META: Keep SonarCloud happy
    }
}
