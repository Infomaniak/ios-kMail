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
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct ShortcutModifier: ViewModifier {
    @EnvironmentObject private var actionsManager: ActionsManager
    @EnvironmentObject private var mainViewState: MainViewState

    @LazyInjectService private var matomo: MatomoUtils
    @LazyInjectService private var platformDetector: PlatformDetectable

    @ObservedObject var viewModel: ThreadListViewModel
    @ObservedObject var multipleSelectionViewModel: ThreadListMultipleSelectionViewModel

    func body(content: Content) -> some View {
        ZStack {
            VStack {
                Button(MailResourcesStrings.Localizable.actionDelete, action: shortcutDelete)
                    .keyboardShortcut(.delete, modifiers: [])

                Button(MailResourcesStrings.Localizable.actionReply, action: shortcutReply)
                    .keyboardShortcut("r")

                Button(MailResourcesStrings.Localizable.buttonNewMessage, action: shortcutNewMessage)
                    .keyboardShortcut("n")

                Button(MailResourcesStrings.Localizable.shortcutRefreshAction, action: shortcutRefresh)
                    .keyboardShortcut("n", modifiers: [.shift, .command])

                Button(MailResourcesStrings.Localizable.shortcutNextAction, action: shortcutNext)
                    .keyboardShortcut(.downArrow, modifiers: platformDetector.isMac ? [] : [.command])

                Button(MailResourcesStrings.Localizable.shortcutPreviousAction, action: shortcutPrevious)
                    .keyboardShortcut(.upArrow, modifiers: platformDetector.isMac ? [] : [.command])
            }
            .frame(width: 0, height: 0)
            .hidden()

            content
        }
    }

    private func shortcutDelete() {
        matomo.track(eventWithCategory: .keyboardShortcutActions, action: .input, name: "delete")

        let messages: [Message]
        if multipleSelectionViewModel.isEnabled {
            messages = multipleSelectionViewModel.selectedItems.flatMap(\.messages)
        } else {
            guard let unwrapMessages = mainViewState.selectedThread?.messages.toArray() else { return }
            messages = unwrapMessages
        }
        Task {
            try await actionsManager.performAction(
                target: messages,
                action: .delete,
                origin: .shortcut(originFolder: viewModel.frozenFolder)
            )
        }
    }

    private func shortcutReply() {
        matomo.track(eventWithCategory: .keyboardShortcutActions, action: .input, name: "reply")

        guard !multipleSelectionViewModel.isEnabled,
              let message = mainViewState.selectedThread?
              .lastMessageToExecuteAction(currentMailboxEmail: viewModel.mailboxManager.mailbox.email) else { return }
        Task {
            try await actionsManager.performAction(
                target: [message],
                action: .reply,
                origin: .shortcut(originFolder: viewModel.frozenFolder)
            )
        }
    }

    private func shortcutNewMessage() {
        matomo.track(eventWithCategory: .keyboardShortcutActions, action: .input, name: "newMessage")

        mainViewState.composeMessageIntent = .new(originMailboxManager: viewModel.mailboxManager)
    }

    private func shortcutRefresh() {
        matomo.track(eventWithCategory: .keyboardShortcutActions, action: .input, name: "refresh")

        Task {
            await viewModel.fetchThreads()
        }
    }

    private func shortcutNext() {
        guard !multipleSelectionViewModel.isEnabled else { return }
        matomo.track(eventWithCategory: .keyboardShortcutActions, action: .input, name: "nextThread")
        viewModel.nextThread()
    }

    private func shortcutPrevious() {
        guard !multipleSelectionViewModel.isEnabled else { return }
        matomo.track(eventWithCategory: .keyboardShortcutActions, action: .input, name: "previousThread")
        viewModel.previousThread()
    }
}

extension View {
    func shortcutModifier(viewModel: ThreadListViewModel,
                          multipleSelectionViewModel: ThreadListMultipleSelectionViewModel) -> some View {
        modifier(ShortcutModifier(viewModel: viewModel,
                                  multipleSelectionViewModel: multipleSelectionViewModel))
    }
}
