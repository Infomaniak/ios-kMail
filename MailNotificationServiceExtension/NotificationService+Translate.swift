//
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
import MailResources

extension NotificationService {
    /// Specific messages that should be translated
    enum WellKnownMessages: String {
        case gotNewMail = "com.infomaniak.got_new_mail"
    }

    /// Translate message if needed
    func translateKnownNotifications() {
        guard let bestAttemptContent = bestAttemptContent else {
            return
        }

        let title = bestAttemptContent.title
        switch title {
        case WellKnownMessages.gotNewMail.rawValue:
            bestAttemptContent.title = MailResourcesStrings.Localizable.notificationTitleNewEmail
            bestAttemptContent.body = ""
            bestAttemptContent.sound = .default
            bestAttemptContent.userInfo = [:]

        default: break
        }
    }
}
