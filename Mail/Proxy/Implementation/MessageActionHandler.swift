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
import InfomaniakCoreUI
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

    func handleTapOnNotification(messageUid: String, mailbox: Mailbox, mailboxManager: MailboxManager) async {
        matomo.track(eventWithCategory: .notificationAction, name: ActionNames.open)

        // Switch account if needed
        switchAccountIfNeeded(mailbox: mailbox, mailboxManager: mailboxManager)

        NotificationCenter.default.post(name: .onUserTappedNotification,
                                        object: NotificationTappedPayload(messageId: messageUid))
    }

    func handleReplyOnNotification(messageUid: String, mailbox: Mailbox, mailboxManager: MailboxManager) {
        matomo.track(eventWithCategory: .notificationAction, name: ActionNames.reply)

        // Switch account if needed
        switchAccountIfNeeded(mailbox: mailbox, mailboxManager: mailboxManager)

        NotificationCenter.default.post(name: .onUserTappedReplyToNotification,
                                        object: NotificationTappedPayload(messageId: messageUid))
    }

    func handleArchiveOnNotification(messageUid: String, mailbox: Mailbox, mailboxManager: MailboxManager) async throws {
        let uiBackgroundTask = await UIApplicationBackgroundTaskHelper(identifier: #function + UUID().uuidString)

        matomo.track(eventWithCategory: .notificationAction, name: ActionNames.archive)

        try await moveMessage(uid: messageUid, to: .archive, mailboxManager: mailboxManager)

        await updateUnreadBadgeCount()

        matomo.track(eventWithCategory: .notificationAction, name: ActionNames.archiveExecuted)

        await uiBackgroundTask.end()
    }

    func handleDeleteOnNotification(messageUid: String, mailbox: Mailbox, mailboxManager: MailboxManager) async throws {
        let uiBackgroundTask = await UIApplicationBackgroundTaskHelper(identifier: #function + UUID().uuidString)

        matomo.track(eventWithCategory: .notificationAction, name: ActionNames.delete)

        try await moveMessage(uid: messageUid, to: .trash, mailboxManager: mailboxManager)

        await updateUnreadBadgeCount()

        matomo.track(eventWithCategory: .notificationAction, name: ActionNames.deleteExecuted)

        await uiBackgroundTask.end()
    }

    /// - Private

    /// Silently move mail to a specified folder
    private func moveMessage(uid: String, to folderRole: FolderRole, mailboxManager: MailboxManager) async throws {
        let realm = mailboxManager.getRealm()
        realm.refresh()

        guard let notificationMessage = realm.object(ofType: Message.self, forPrimaryKey: uid) else {
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

    /// Update the unread count
    private func updateUnreadBadgeCount() async {
        let unreadCount = await NotificationsHelper.getUnreadCount()
        if #available(iOS 16.0, *) {
            try? await UNUserNotificationCenter.current().setBadgeCount(unreadCount)
        } else {
            Task { @MainActor in
                UIApplication.shared.applicationIconBadgeNumber = unreadCount
            }
        }
    }
}

/// Something to generate and track an UIApplication.BackgroundTask in a modern Async/Await context.
///
/// TODO: move to CoreUI
@available(iOSApplicationExtension, unavailable)
final class UIApplicationBackgroundTaskHelper {
    /// A background task identifier
    private let identifier: String

    /// Callback to execute on a task expiration. Performed on MainActor.
    private var expirationHandler: (() async -> Void)?

    private var _state: UIBackgroundTaskIdentifier = .invalid
    public var state: UIBackgroundTaskIdentifier? {
        guard _state != .invalid else {
            return nil
        }

        return _state
    }

    public init(identifier: String, expirationHandler: (() -> Void)? = nil) async {
        self.identifier = identifier
        self.expirationHandler = expirationHandler
        await begin()
    }

    /// perform the beginBackgroundTask
    private func begin() async {
        _state = await UIApplication.shared.beginBackgroundTask(withName: identifier) {
            guard let currentState = self.state else {
                return
            }

            self._state = .invalid
            Task { @MainActor in
                await self.expirationHandler?()

                UIApplication.shared.endBackgroundTask(currentState)
            }
        }
    }

    /// Terminate a background task
    public func end() async {
        guard let currentState = state else {
            return
        }

        _state = .invalid
        await UIApplication.shared.endBackgroundTask(currentState)
    }
}
