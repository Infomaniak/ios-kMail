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
import MailCore
import SwiftUI

struct ShortcutModifier: ViewModifier {
    @EnvironmentObject private var actionsManager: ActionsManager

    @ObservedObject var viewModel: ThreadListViewModel
    @ObservedObject var multipleSelectionViewModel: ThreadListMultipleSelectionViewModel

    func body(content: Content) -> some View {
        ZStack {
            VStack {
                Button("Delete shortcut", action: shortcutDelete)
                    .keyboardShortcut(.delete)
            }

            content
        }
    }

    private func shortcutDelete() {
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
}

extension View {
    func shortcutModifier(viewModel: ThreadListViewModel,
                          multipleSelectionViewModel: ThreadListMultipleSelectionViewModel) -> some View {
        modifier(ShortcutModifier(viewModel: viewModel,
                                  multipleSelectionViewModel: multipleSelectionViewModel))
    }
}
