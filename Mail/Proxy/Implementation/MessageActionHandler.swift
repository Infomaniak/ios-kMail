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
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore
import RealmSwift
import UIKit
import UserNotifications

public struct MessageActionHandler: MessageActionHandlable {
    private enum ErrorDomain: Error {
        case messageNotFoundInDatabase
    }

    private enum ActionNames {
        static let archive = "archiveClicked"
        static let delete = "deleteClicked"
        static let reply = "reply"
        static let open = "open"

        static let archiveExecuted = "archiveExecuted"
        static let deleteExecuted = "deleteExecuted"
    }

    @LazyInjectService private var accountManager: AccountManager
    @LazyInjectService private var matomo: MatomoUtils
    @LazyInjectService private var snackbarPresenter: IKSnackBarPresentable

    private enum Action {
        case tap
        case reply
    }

    private func handleNotification(action: Action, messageUid: String, mailbox: Mailbox, mailboxManager: MailboxManager) async {
        switchAccountIfNeeded(mailbox: mailbox, mailboxManager: mailboxManager)

        guard let inbox = mailboxManager.getFolder(with: .inbox)?.freezeIfNeeded() else { return }

        @InjectService var mainViewStateStore: MainViewStateStore
        let notificationMainViewState = await mainViewStateStore.getOrCreateMainViewState(
            for: mailboxManager,
            initialFolder: inbox
        )

        let tappedNotificationMessage = mailboxManager.fetchObject(ofType: Message.self, forPrimaryKey: messageUid)?
            .freezeIfNeeded()

        Task { @MainActor in
            switch action {
            case .tap:
                // Original parent should always be in the inbox but maybe change in a later stage to always find the parent in
                // inbox
                if let tappedNotificationThread = tappedNotificationMessage?.originalThread {
                    NotificationCenter.default.post(name: .closeDrawer, object: nil)
                    notificationMainViewState.selectedThread = tappedNotificationThread
                } else {
                    snackbarPresenter.show(message: MailError.localMessageNotFound.errorDescription ?? "")
                }
            case .reply:
                if let tappedNotificationMessage {
                    NotificationCenter.default.post(name: .closeDrawer, object: nil)
                    notificationMainViewState.composeMessageIntent = .replyingTo(
                        message: tappedNotificationMessage,
                        replyMode: .reply,
                        originMailboxManager: mailboxManager
                    )
                } else {
                    snackbarPresenter.show(message: MailError.localMessageNotFound.errorDescription ?? "")
                }
            }
        }
    }

    func handleTapOnNotification(messageUid: String, mailbox: Mailbox, mailboxManager: MailboxManager) async {
        matomo.track(eventWithCategory: .notificationActions, name: ActionNames.open)
        await handleNotification(action: .tap, messageUid: messageUid, mailbox: mailbox, mailboxManager: mailboxManager)
    }

    func handleReplyOnNotification(messageUid: String, mailbox: Mailbox, mailboxManager: MailboxManager) async {
        matomo.track(eventWithCategory: .notificationActions, name: ActionNames.reply)
        await handleNotification(action: .reply, messageUid: messageUid, mailbox: mailbox, mailboxManager: mailboxManager)
    }

    func handleArchiveOnNotification(messageUid: String, mailboxManager: MailboxManager) async throws {
        let expiringActivity = ExpiringActivity(id: #function + UUID().uuidString)
        expiringActivity.start()

        matomo.track(eventWithCategory: .notificationActions, name: ActionNames.archive)

        try await moveMessage(uid: messageUid, to: .archive, mailboxManager: mailboxManager)

        await updateUnreadBadgeCount()

        matomo.track(eventWithCategory: .notificationActions, name: ActionNames.archiveExecuted)

        expiringActivity.endAll()
    }

    func handleDeleteOnNotification(messageUid: String, mailboxManager: MailboxManager) async throws {
        let expiringActivity = ExpiringActivity(id: #function + UUID().uuidString)
        expiringActivity.start()

        matomo.track(eventWithCategory: .notificationActions, name: ActionNames.delete)

        try await moveMessage(uid: messageUid, to: .trash, mailboxManager: mailboxManager)

        await updateUnreadBadgeCount()

        matomo.track(eventWithCategory: .notificationActions, name: ActionNames.deleteExecuted)

        expiringActivity.endAll()
    }

    /// - Private

    /// Silently move mail to a specified folder
    private func moveMessage(uid: String, to folderRole: FolderRole, mailboxManager: MailboxManager) async throws {
        guard let notificationMessage = mailboxManager.fetchObject(ofType: Message.self, forPrimaryKey: uid) else {
            throw ErrorDomain.messageNotFoundInDatabase
        }

        _ = try await mailboxManager.move(messages: [notificationMessage.freezeIfNeeded()], to: folderRole)
    }

    /// Switch logged in account if needed, given a mailbox and a mailboxManager
    /// - Parameters:
    ///   - mailbox: the mailbox related to a message
    ///   - mailboxManager: the mailboxmanager
    private func switchAccountIfNeeded(mailbox: Mailbox, mailboxManager: MailboxManager) {
        if accountManager.currentMailboxManager?.mailbox != mailboxManager.mailbox {
            if accountManager.getCurrentAccount()?.userId != mailboxManager.mailbox.userId {
                if let switchedAccount = accountManager.accounts
                    .first(where: { $0.userId == mailboxManager.mailbox.userId }) {
                    accountManager.switchAccount(newUserId: switchedAccount.userId)
                    accountManager.switchMailbox(newMailbox: mailbox)
                }
            } else {
                accountManager.switchMailbox(newMailbox: mailbox)
            }
        }
    }

    /// Update the unread count
    private func updateUnreadBadgeCount() async {
        let unreadCount = await NotificationsHelper.getUnreadCount()
        try? await UNUserNotificationCenter.current().setBadgeCount(unreadCount)
    }
}
