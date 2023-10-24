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
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import SwiftUI

struct ShortcutModifier: ViewModifier {
    @EnvironmentObject private var actionsManager: ActionsManager

    @LazyInjectService private var matomo: MatomoUtils
    @ObservedObject var viewModel: ThreadListViewModel
    @ObservedObject var multipleSelectionViewModel: ThreadListMultipleSelectionViewModel

    func body(content: Content) -> some View {
        ZStack {
            VStack {
                Button("Delete shortcut", action: shortcutDelete)
                    .keyboardShortcut(.delete, modifiers: [])

                Button("Reply shortcut", action: shortcutReply)
                    .keyboardShortcut("r")

                Button("Refresh shortcut", action: shortcutRefresh)
                    .keyboardShortcut("n", modifiers: [.shift, .command])

                Button("Next thread", action: shortcutNext)
                    .keyboardShortcut(.downArrow, modifiers: [])

                Button("Previous thread", action: shortcutPrevious)
                    .keyboardShortcut(.upArrow, modifiers: [])
            }
            .frame(width: 0, height: 0)
            .hidden()

            content
        }
    }

    private func shortcutDelete() {
        matomo.track(eventWithCategory: .shortcutAction, name: "delete")

        let messages: [Message]
        if multipleSelectionViewModel.isEnabled {
            messages = multipleSelectionViewModel.selectedItems.flatMap(\.messages)
        } else {
            guard let unwrapMessages = viewModel.selectedThread?.messages.toArray() else { return }
            messages = unwrapMessages
        }
        Task {
            try await actionsManager.performAction(
                target: messages,
                action: .delete,
                origin: .shortcut(originFolder: viewModel.folder.freezeIfNeeded())
            )
        }
    }

    private func shortcutReply() {
        matomo.track(eventWithCategory: .shortcutAction, name: "reply")

        guard !multipleSelectionViewModel.isEnabled,
              let message = viewModel.selectedThread?
              .lastMessageToExecuteAction(currentMailboxEmail: viewModel.mailboxManager.mailbox.email) else { return }
        Task {
            try await actionsManager.performAction(
                target: [message],
                action: .reply,
                origin: .shortcut(originFolder: viewModel.folder.freezeIfNeeded())
            )
        }
    }

    private func shortcutRefresh() {
        matomo.track(eventWithCategory: .shortcutAction, name: "refresh")

        Task {
            await viewModel.fetchThreads()
        }
    }

    private func shortcutNext() {
        guard !multipleSelectionViewModel.isEnabled else { return }
        matomo.track(eventWithCategory: .shortcutAction, name: "nextThread")
        viewModel.nextThread()
    }

    private func shortcutPrevious() {
        guard !multipleSelectionViewModel.isEnabled else { return }
        matomo.track(eventWithCategory: .shortcutAction, name: "previousThread")
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
