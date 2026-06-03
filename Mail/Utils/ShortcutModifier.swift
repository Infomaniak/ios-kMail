/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftModalPresentation
import SwiftUI

struct ShortcutModifier: ViewModifier {
    @EnvironmentObject private var actionsManager: ActionsManager
    @EnvironmentObject private var mainViewState: MainViewState
    @EnvironmentObject private var actionsProvider: ActionsProvider

    @ModalState private var destructiveAlert: DestructiveActionAlertState?

    @ObservedObject var viewModel: ThreadListViewModel
    @ObservedObject var multipleSelectionViewModel: MultipleSelectionViewModel

    private var origin: ActionOrigin {
        return .shortcut(originFolder: viewModel.frozenFolder,
                         nearestDestructiveAlert: $destructiveAlert)
    }

    private var actions: [Action] {
        var messages: [Message]
        if multipleSelectionViewModel.isEnabled {
            messages = multipleSelectionViewModel.selectedItems.values.flatMap(\.messages)
        } else {
            messages = mainViewState.selectedThread?.messages.toArray() ?? []
        }

        return actionsProvider.actionsFor(origin: origin, messages: messages)
    }

    func body(content: Content) -> some View {
        ZStack {
            VStack {
                ForEach(actions) { action in
                    if let shortcut = action.keyboardShortcut {
                        Button(action.title) {
                            executeAction(action: action)
                        }
                        .keyboardShortcut(shortcut.key, modifiers: shortcut.modifiers)
                    }
                }
            }
            .frame(width: 0, height: 0)
            .hidden()

            content
        }
        .mailCustomAlert(item: $destructiveAlert) { item in
            DestructiveActionAlertView(destructiveAlert: item)
        }
    }

    private func executeAction(action: Action) {
        if action == .refresh {
            shortcutRefresh()
        } else if action == .writeEmailAction {
            shortcutNewMessage()
        } else {
            var messages: [Message]
            if multipleSelectionViewModel.isEnabled {
                messages = multipleSelectionViewModel.selectedItems.values.flatMap(\.messages)
            } else {
                messages = mainViewState.selectedThread?.messages.toArray() ?? []
            }
            multipleSelectionViewModel.disable()
            guard !messages.isEmpty else { return }
            Task {
                try await actionsManager.performAction(
                    target: messages,
                    action: action,
                    origin: origin
                )
            }
        }
    }

    private func shortcutNewMessage() {
        @InjectService var matomo: MatomoUtils
        matomo.track(eventWithCategory: .keyboardShortcutActions, action: .input, name: "newMessage")

        mainViewState.composeMessageIntent = .new(originMailboxManager: viewModel.mailboxManager)
    }

    private func shortcutRefresh() {
        @InjectService var matomo: MatomoUtils
        matomo.track(eventWithCategory: .keyboardShortcutActions, action: .input, name: "refresh")

        Task {
            await viewModel.fetchThreads()
        }
    }
}

extension View {
    func shortcutModifier(viewModel: ThreadListViewModel,
                          multipleSelectionViewModel: MultipleSelectionViewModel) -> some View {
        modifier(ShortcutModifier(viewModel: viewModel,
                                  multipleSelectionViewModel: multipleSelectionViewModel))
    }
}
