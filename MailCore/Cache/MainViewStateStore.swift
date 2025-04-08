/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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

public class MainViewStateStore {
    private var mainViewStates = [String: MainViewState]()

    @MainActor
    public func getOrCreateMainViewState(for mailboxManager: MailboxManager, initialFolder: Folder) -> MainViewState {
        if let mainViewState = mainViewStates[mailboxManager.mailbox.uuid] {
            return mainViewState
        } else {
            let mainViewState = MainViewState(mailboxManager: mailboxManager, selectedFolder: initialFolder)
            mainViewStates[mailboxManager.mailbox.uuid] = mainViewState
            return mainViewState
        }
    }

    @MainActor
    public func getExistingMainViewState(for mailboxManager: MailboxManager) -> MainViewState? {
        return mainViewStates[mailboxManager.mailbox.uuid]
    }
}
