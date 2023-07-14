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
import InfomaniakCore

public class UserActivityController {
    var currentActivity: NSUserActivity?

    public init() {}

    public func setCurrentActivity(
        _ activity: NSUserActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb),
        mailbox: Mailbox,
        folder: Folder?
    ) {
        guard let folder,
              let mailboxIndex = getMailboxIndexForCustomOrder(mailbox) else {
            return
        }

        currentActivity?.invalidate()
        currentActivity = activity
        currentActivity?.webpageURL = Endpoint.currentUserActivity(mailboxIndex: mailboxIndex, folder: folder).url
        currentActivity?.becomeCurrent()
    }

    private func getMailboxIndexForCustomOrder(_ mailbox: Mailbox) -> Int? {
        let sortedUserMailboxes = MailboxInfosManager.instance.getMailboxes(for: mailbox.userId).sorted {
            if $0.isPrimary {
                return true
            } else if $1.isPrimary {
                return false
            } else {
                return $0.email < $1.email
            }
        }
        return sortedUserMailboxes.firstIndex { $0.objectId == mailbox.objectId }
    }
}
