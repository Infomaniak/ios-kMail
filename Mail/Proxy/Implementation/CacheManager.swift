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
import Contacts
import Foundation
import InfomaniakCore
import InfomaniakDI
import MailCore

@available(iOSApplicationExtension, unavailable)
public final class CacheManager: CacheManageable {
    @LazyInjectService private var accountManager: AccountManager

    public func refreshCacheData(account: Account?) {
        guard let account else { return }

        // Try to enable at least once before attempting fetching new user
        accountManager.enableBugTrackerIfAvailable()

        Task {
            do {
                try await accountManager.updateUser(for: account)
                accountManager.enableBugTrackerIfAvailable()

                guard CNContactStore.authorizationStatus(for: .contacts) != .notDetermined else {
                    return
                }
                try await accountManager.currentContactManager?.refreshContactsAndAddressBooksIfNeeded()
            } catch {
                DDLogError("Error while updating user account: \(error)")
            }
        }
    }
}
