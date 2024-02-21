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

import CocoaLumberjackSwift
import Foundation
import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import UserNotifications

// TODO: Move to CoreUI / use with kDrive

/// Something that can present a message to the user, abstracted of execution context (App / NSExtension)
///
/// Will present a snackbar while main app is opened, a local notification in Extension or Background.
public protocol UserAlertDisplayable {
    /// Will present a snackbar while main app is opened, a local notification in Extension or Background.
    /// - Parameter message: The message to display
    func show(message: String)

    /// Will present a snackbar while main app is opened, a local notification in Extension or Background.
    /// - Parameters:
    ///   - message: The message to display
    ///   - action:  Title and closure associated with the action
    func show(message: String, action: UserAlertAction)
}

public typealias UserAlertAction = (name: String, closure: () -> Void)

public final class UserAlertDisplayer: UserAlertDisplayable {
    @LazyInjectService private var snackbarPresenter: SnackBarPresentable
    @LazyInjectService private var applicationState: ApplicationStatable

    /// Used by DI
    public init() {
        // META: keep SonarCloud happy
    }

    // MARK: - UserAlertDisplayable

    public func show(message: String) {
        showInContext(message: message, action: nil)
    }

    public func show(message: String, action: UserAlertAction) {
        showInContext(message: message, action: action)
    }

    // MARK: - private

    private func showInContext(message: String, action: UserAlertAction?) {
        Task { @MainActor in
            // check not in extension mode
            guard !Bundle.main.isExtension else {
                presentInLocalNotification(message: message, action: action)
                return
            }

            // if app not in foreground, we use the local notifications
            guard applicationState.applicationState == .active else {
                presentInLocalNotification(message: message, action: action)
                return
            }

            // Present the message as we are in foreground app context
            presentInSnackbar(message: message, action: action)
        }
    }

    // MARK: Private

    private func presentInSnackbar(message: String, action: UserAlertAction?) {
        guard let action else {
            snackbarPresenter.show(message: message)
            return
        }

        let snackBarAction = IKSnackBar.Action(title: action.name, action: action.closure)
        snackbarPresenter.show(message: message, action: snackBarAction)
    }

    private func presentInLocalNotification(message: String, action: UserAlertAction?) {
        if action != nil {
            DDLogError("Action not implemented in notifications for now")
        }

        let content = UNMutableNotificationContent()
        content.body = message

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.3, repeats: false)
        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request) { error in
            DDLogError("UserAlertDisplayer local notification error:\(String(describing: error)) ")
        }

        // Self destruct this notification, as used only for user feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            notificationCenter.removeDeliveredNotifications(withIdentifiers: [uuidString])
        }
    }
}
