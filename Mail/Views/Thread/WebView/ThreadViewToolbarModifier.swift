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

import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftModalPresentation
import SwiftUI

extension View {
    func threadViewToolbar(frozenThread: Thread) -> some View {
        modifier(ThreadViewToolbarModifier(frozenThread: frozenThread))
    }
}

struct ThreadViewToolbarModifier: ViewModifier {
    @EnvironmentObject private var mailboxManager: MailboxManager
    @EnvironmentObject private var actionsManager: ActionsManager

    @Environment(\.isCompactWindow) private var isCompactWindow

    private let frozenThread: Thread
    private let frozenFolder: Folder?

    init(frozenThread: Thread) {
        self.frozenThread = frozenThread

        frozenFolder = frozenThread.folder
    }

    func body(content: Content) -> some View {
        if isCompactWindow {
            content.compactToolbar(frozenThread: frozenThread)
        } else {
            content.largeToolbar(frozenThread: frozenThread)
        }
    }

    private func canPerformAction(_ action: Action) -> Bool {
        switch action {
        case .reply, .forward:
            return actionsManager.canSendEmails
        default:
            return true
        }
    }
}
