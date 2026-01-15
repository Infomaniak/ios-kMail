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

import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct CustomCommands: Commands {
    @ObservedObject var rootViewState: RootViewState

    var mainViewState: MainViewState? {
        if case .mainView(_, let mainViewState) = rootViewState.state {
            return mainViewState
        } else {
            return nil
        }
    }

    var body: some Commands {
        CommandMenu(MailResourcesStrings.Localizable.messageMenuTitle) {
            if let mainViewState {
                MessageCommands(mainViewState: mainViewState)
            }
        }

        CommandGroup(replacing: .newItem) {
            NewMessageCommand(mailboxManager: mainViewState?.mailboxManager)

            NewWindowCommand()
        }

        CommandGroup(after: .importExport) {
            Button(MailResourcesStrings.Localizable.shortcutRefreshAction) {
                guard let mainViewState else { return }
                refresh(mailboxManager: mainViewState.mailboxManager, currentFolder: mainViewState.selectedFolder)
            }
            .keyboardShortcut("n", modifiers: [.shift, .command])
            .disabled(mainViewState == nil)
        }

        CommandGroup(replacing: .printItem) {
            if let mainViewState {
                PrintMessageCommand(mainViewState: mainViewState)
            }
        }

        CommandGroup(replacing: .appSettings) {
            OpenSettingsCommand()
                .disabled(mainViewState == nil)
        }
    }

    func refresh(mailboxManager: MailboxManager, currentFolder: Folder) {
        @InjectService var matomo: MatomoUtils
        matomo.track(eventWithCategory: .menuAction, name: "refresh")
        Task {
            await mailboxManager.refreshFolderContent(currentFolder)
        }
    }
}
