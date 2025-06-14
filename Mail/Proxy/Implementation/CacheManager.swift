/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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

import Contacts
import Foundation
import InfomaniakCore
import InfomaniakDI
import InfomaniakLogin
import MailCore
import OSLog

@available(iOSApplicationExtension, unavailable)
public actor CacheManager: CacheManageable {
    @LazyInjectService private var accountManager: AccountManager

    private var refreshCacheDataTaskForUserId: [Int: Task<Void, Never>] = [:]

    public func refreshCacheDataFor(userId: Int) async {
        if let refreshCacheDataTask = refreshCacheDataTaskForUserId[userId] {
            await refreshCacheDataTask.value
            return
        }

        refreshCacheDataTaskForUserId[userId] = Task {
            await uniqueRefreshCacheDataFor(userId: userId)
            refreshCacheDataTaskForUserId[userId] = nil
        }

        await refreshCacheDataTaskForUserId[userId]?.value
    }

    private func uniqueRefreshCacheDataFor(userId: Int) async {
        guard let account = accountManager.account(for: userId) else { return }

        // Try to enable at least once before attempting fetching new user
        await accountManager.enableBugTrackerIfAvailable()

        do {
            try await accountManager.updateUser(for: account)
            await accountManager.enableBugTrackerIfAvailable()

            guard CNContactStore.authorizationStatus(for: .contacts) != .notDetermined else {
                return
            }

            let apiFetcher = accountManager.getApiFetcher(for: account.userId, token: account)
            let contactManager = accountManager.getContactManager(for: userId, apiFetcher: apiFetcher)

            try await contactManager.refreshContactsAndAddressBooksIfNeeded()
        } catch {
            Logger.general.error("Error while updating user account: \(error)")
        }
    }
}
