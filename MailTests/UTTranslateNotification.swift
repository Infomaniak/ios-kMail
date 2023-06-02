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
@testable import MailNotificationServiceExtension
import MailResources
import UserNotifications
import XCTest

final class UTTranslateNotification: XCTestCase {
    func testTranslateUnknownNotification() throws {
        // GIVEN
        let notificationService = NotificationService()
        let notification = UNMutableNotificationContent()
        let title = "Trololololo"
        notification.title = title
        notificationService.bestAttemptContent = notification

        // WHEN
        notificationService.translateKnownNotifications()

        // THEN
        XCTAssertEqual(notification.title, title, "The title should not change")
    }

    func testTranslateEmptyTitleNotification() throws {
        // GIVEN
        let notificationService = NotificationService()
        let notification = UNMutableNotificationContent()
        let title = ""
        notification.title = title
        notificationService.bestAttemptContent = notification

        // WHEN
        notificationService.translateKnownNotifications()

        // THEN
        XCTAssertEqual(notification.title, title, "The title should not change, and still be nil")
    }

    func testTranslateKnownNotification() throws {
        // GIVEN
        let notificationService = NotificationService()
        let notification = UNMutableNotificationContent()
        let title = NotificationService.WellKnownMessages.gotNewMail.rawValue
        notification.title = title
        notificationService.bestAttemptContent = notification

        // WHEN
        notificationService.translateKnownNotifications()

        // THEN
        XCTAssertEqual(
            notification.title,
            MailResourcesStrings.Localizable.notificationTitleNewEmail
        )
    }
}
