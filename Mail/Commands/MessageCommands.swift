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

struct MessageCommands: View {
    @Environment(\.openWindow) private var openWindow

    @ObservedObject var mainViewState: MainViewState

    private var lastMessageFromFolder: Message? {
        mainViewState.selectedThread?.lastMessageFromFolder
    }

    var body: some View {
        Button(MailResourcesStrings.Localizable.actionReply) {
            replyToMessage(message: lastMessageFromFolder, replyMode: .reply, mailboxManager: mainViewState.mailboxManager)
        }
        .keyboardShortcut("r")
        .disabled(lastMessageFromFolder == nil)

        Button(MailResourcesStrings.Localizable.actionReplyAll) {
            replyToMessage(message: lastMessageFromFolder, replyMode: .replyAll, mailboxManager: mainViewState.mailboxManager)
        }
        .keyboardShortcut("r", modifiers: [.shift, .command])
        .disabled(lastMessageFromFolder == nil)

        Button(MailResourcesStrings.Localizable.actionForward) {
            replyToMessage(message: lastMessageFromFolder, replyMode: .forward, mailboxManager: mainViewState.mailboxManager)
        }
        .keyboardShortcut("f", modifiers: [.shift, .command])
        .disabled(lastMessageFromFolder == nil)
    }

    func replyToMessage(message: Message?, replyMode: ReplyMode, mailboxManager: MailboxManager) {
        guard let message else { return }

        @InjectService var matomo: MatomoUtils
        matomo.track(eventWithCategory: .menuAction, name: replyMode.rawValue)
        openWindow(
            id: DesktopWindowIdentifier.composeWindowIdentifier,
            value: ComposeMessageIntent.replyingTo(message: message, replyMode: replyMode, originMailboxManager: mailboxManager)
        )
    }
}
