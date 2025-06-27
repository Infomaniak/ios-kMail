/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailResources
import RealmSwift
import SwiftUI
import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {
    // periphery:ignore - Making sure the DI is registered at a very early stage of the app launch.
    private let dependencyInjectionHook = NotificationContentExtensionTargetAssembly()

    @LazyInjectService private var accountManager: AccountManager
    @LazyInjectService private var mailboxInfosManager: MailboxInfosManager

    let activityIndicator = UIActivityIndicatorView(style: .medium)
    let errorLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        SentryDebug.setUserId(accountManager.currentUserId)
        ModelMigrator().migrateRealmIfNeeded()

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)

        errorLabel.isHidden = true
        errorLabel.font = UIFont.preferredFont(forTextStyle: .body)
        errorLabel.textAlignment = .center
        errorLabel.textColor = .secondaryLabel
        errorLabel.text = MailResourcesStrings.Localizable.errorMessageNotFound
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(errorLabel)

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        view.window?.updateUI(accent: UserDefaults.shared.accentColor, theme: UserDefaults.shared.theme)
    }

    func stopAnimating(displayError: Bool) {
        activityIndicator.stopAnimating()
        errorLabel.isHidden = displayError
    }

    func didReceive(_ notification: UNNotification) {
        Task {
            let userInfo = notification.request.content.userInfo
            let userId = userInfo[NotificationsHelper.UserInfoKeys.userId] as? Int

            SentryDebug.setUserId(userId ?? accountManager.currentUserId)

            guard let mailboxId = userInfo[NotificationsHelper.UserInfoKeys.mailboxId] as? Int,
                  let userId,
                  let messageUid = userInfo[NotificationsHelper.UserInfoKeys.messageUid] as? String,
                  let mailbox = mailboxInfosManager.getMailbox(id: mailboxId, userId: userId),
                  let mailboxManager = accountManager.getMailboxManager(for: mailbox) else {
                stopAnimating(displayError: true)
                return
            }

            guard let currentUser = await accountManager.userProfileStore.getUserProfile(id: userId) else { return }

            guard let message = try? await NotificationsHelper.fetchMessage(uid: messageUid, in: mailboxManager) else {
                stopAnimating(displayError: true)
                return
            }

            let messageWorker = MessagesWorker(mailboxManager: mailboxManager)
            let messageView = ScrollView {
                MessageView(threadForcedExpansion: .constant([messageUid: .expanded]), message: message)
                    .environment(\.isMessageInteractive, false)
                    .environment(\.currentUser, MandatoryEnvironmentContainer(value: currentUser))
                    .environmentObject(mailboxManager)
                    .environmentObject(messageWorker)
            }

            let hostingViewController = UIHostingController(rootView: messageView)

            addChild(hostingViewController)
            view.addSubview(hostingViewController.view)
            hostingViewController.view.frame = view.bounds
            stopAnimating(displayError: false)
        }
    }
}
