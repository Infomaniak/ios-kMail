/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import InfomaniakDI
import MailCore
import MailResources
import RealmSwift
import SwiftUI
import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {
    private let dependencyInjectionHook = NotificationContentExtensionTargetAssembly()

    @LazyInjectService private var accountManager: AccountManager
    @LazyInjectService private var mailboxInfosManager: MailboxInfosManager

    let activityIndicator = UIActivityIndicatorView(style: .medium)
    let errorLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        ModelMigrator().migrateRealmIfNeeded()
        SentryDebug.setUserId(accountManager.currentUserId)

        activityIndicator.hidesWhenStopped = true
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()

        errorLabel.font = UIFont.preferredFont(forTextStyle: .body)
        errorLabel.textAlignment = .center
        errorLabel.textColor = .secondaryLabel
        errorLabel.text = MailResourcesStrings.Localizable.errorMessageNotFound
    }

    func stopAnimating(displayError: Bool) {
        activityIndicator.stopAnimating()
        if displayError {
            errorLabel.sizeToFit()
            errorLabel.center = view.center
            view.addSubview(errorLabel)
        }
    }

    func didReceive(_ notification: UNNotification) {
        Task {
            let userInfo = notification.request.content.userInfo
            guard let mailboxId = userInfo[NotificationsHelper.UserInfoKeys.mailboxId] as? Int,
                  let userId = userInfo[NotificationsHelper.UserInfoKeys.userId] as? Int,
                  let messageUid = userInfo[NotificationsHelper.UserInfoKeys.messageUid] as? String,
                  let mailbox = mailboxInfosManager.getMailbox(id: mailboxId, userId: userId),
                  let mailboxManager = accountManager.getMailboxManager(for: mailbox) else {
                stopAnimating(displayError: true)
                return
            }

            guard let message = try? await NotificationsHelper.fetchMessage(uid: messageUid, in: mailboxManager) else {
                stopAnimating(displayError: true)
                return
            }

            let messageView = ScrollView {
                MessageView(
                    message: message,
                    isMessageExpanded: true,
                    threadForcedExpansion: .constant([:])
                )
                .environment(\.isMessageInteractive, false)
                .environmentObject(mailboxManager)
            }

            let hostingViewController = UIHostingController(rootView: messageView)

            addChild(hostingViewController)
            view.addSubview(hostingViewController.view)
            hostingViewController.view.frame = view.bounds
            stopAnimating(displayError: false)
        }
    }
}
