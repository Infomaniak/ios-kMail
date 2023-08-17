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
import InfomaniakDI
import MailCore
import RealmSwift
import UIKit
import UserNotifications

/// Something that take care of actions related to a message
protocol MessageActionHandlable {
    /// Present the new mail to the user with the correct account
    func handleTapOnNotification(messageUid: String, mailbox: Mailbox, mailboxManager: MailboxManager) async

    /// Silently move mail to `archive` folder
    func handleArchiveOnNotification(messageUid: String, mailbox: Mailbox, mailboxManager: MailboxManager) async

    /// Silently move mail to `trash` folder
    func handleDeleteOnNotification(messageUid: String, mailbox: Mailbox, mailboxManager: MailboxManager) async

    /// Present a new `reply to` draft to the user with the correct account
    func handleReplyOnNotification(messageUid: String, mailbox: Mailbox, mailboxManager: MailboxManager)
}

public struct MessageActionHandler: MessageActionHandlable {
    @LazyInjectService private var accountManager: AccountManager

    func handleTapOnNotification(messageUid: String, mailbox: Mailbox, mailboxManager: MailboxManager) async {
        // Switch account if needed
        switchAccountIfNeeded(mailbox: mailbox, mailboxManager: mailboxManager)

        // Open message
        NotificationCenter.default.post(name: .onUserTappedNotification,
                                        object: NotificationTappedPayload(messageId: messageUid))
    }

    func handleReplyOnNotification(messageUid: String, mailbox: Mailbox, mailboxManager: MailboxManager) {
        // Switch account if needed
        switchAccountIfNeeded(mailbox: mailbox, mailboxManager: mailboxManager)

        // Open reply to
        NotificationCenter.default.post(name: .onUserTappedReplyToNotification,
                                        object: NotificationTappedPayload(messageId: messageUid))
    }

    func handleArchiveOnNotification(messageUid: String, mailbox: Mailbox, mailboxManager: MailboxManager) async {
        await moveMessage(uid: messageUid, to: .archive, mailboxManager: mailboxManager)
    }

    func handleDeleteOnNotification(messageUid: String, mailbox: Mailbox, mailboxManager: MailboxManager) async {
        await moveMessage(uid: messageUid, to: .trash, mailboxManager: mailboxManager)
    }

    /// - Private

    /// Silently move mail to a specified folder
    private func moveMessage(uid: String, to folderRole: FolderRole, mailboxManager: MailboxManager) async {
        let realm = mailboxManager.getRealm()
        realm.refresh()

        guard let notificationMessage = realm.object(ofType: Message.self, forPrimaryKey: uid) else {
            // Sentry not able to load fetched mail
            return
        }

        _ = try? await mailboxManager.move(messages: [notificationMessage.freezeIfNeeded()], to: folderRole)
    }

    /// Switch logged in account if needed, given a mailbox and a mailboxManager
    /// - Parameters:
    ///   - mailbox: the mailbox related to a message
    ///   - mailboxManager: the mailboxmanager
    private func switchAccountIfNeeded(mailbox: Mailbox, mailboxManager: MailboxManager) {
        if accountManager.currentMailboxManager?.mailbox != mailboxManager.mailbox {
            if accountManager.getCurrentAccount()?.userId != mailboxManager.mailbox.userId {
                if let switchedAccount = accountManager.accounts.values
                    .first(where: { $0.userId == mailboxManager.mailbox.userId }) {
                    accountManager.switchAccount(newAccount: switchedAccount)
                    accountManager.switchMailbox(newMailbox: mailbox)
                }
            } else {
                accountManager.switchMailbox(newMailbox: mailbox)
            }
        }
    }
}
