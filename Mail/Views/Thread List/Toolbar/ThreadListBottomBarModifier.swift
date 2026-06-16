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

import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

extension View {
    func threadListBottomBar(viewModel: ThreadListViewModel,
                             multipleSelectionViewModel: MultipleSelectionViewModel) -> some View {
        modifier(ThreadListBottomBarModifier(viewModel: viewModel, multipleSelectionViewModel: multipleSelectionViewModel))
    }
}

struct ThreadListBottomBarModifier: ViewModifier {
    @EnvironmentObject private var actionsManager: ActionsManager
    @EnvironmentObject private var mainViewState: MainViewState
    @EnvironmentObject private var actionsProvider: ActionsProvider
    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var multipleSelectedMessages: [Message]?
    @State private var messagesToMove: [Message]? = nil

    @ObservedObject var viewModel: ThreadListViewModel
    @ObservedObject var multipleSelectionViewModel: MultipleSelectionViewModel

    private var isBottomBarVisible: Bool {
        return multipleSelectionViewModel.isEnabled
    }

    private var isShowingBottomBarItems: Bool {
        if #available(iOS 18.0, *) {
            return true
        } else {
            return isBottomBarVisible
        }
    }

    private var shouldDisableArchiveButton: Bool {
        return viewModel.frozenFolder.role == .scheduledDrafts || viewModel.frozenFolder.role == .draft
    }

    private var origin: ActionOrigin {
        return .multipleSelection(originFolder: viewModel.frozenFolder, nearestMessagesToMoveSheet: $multipleSelectedMessages)
    }

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    if isShowingBottomBarItems {
                        moreButton
                    }
                }
            }
            .toolbarSpacer(placement: .bottomBar, isVisible: isShowingBottomBarItems)
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    if isShowingBottomBarItems {
                        let allMessages = multipleSelectionViewModel.selectedItems.values.flatMap(\.messages)
                        ForEach(actionsProvider.actionsFor(origin: origin, messages: allMessages)) { action in
                            Button {
                                performToolbarAction(action)
                            } label: {
                                Label(action.shortTitle ?? action.title, asset: action.icon)
                            }
                            .accessibilityLabel(action.title)
                            .accessibilityAddTraits(.isButton)
                            .disabled(action == .archive && shouldDisableArchiveButton)

                            LegacyToolbarSpacer()
                        }
                    }
                }
            }
            .bottomBarVisibility(visibility: isBottomBarVisible ? .visible : .hidden)
            .sheet(item: $messagesToMove){ messages in
                MoveEmailView(
                    mailboxManager: viewModel.mailboxManager,
                    movedMessages: messages,
                    originFolder: viewModel.frozenFolder
                )
                .sheetViewStyle()
            }
    }

    private var moreButton: some View {
        Button {
            multipleSelectedMessages = multipleSelectionViewModel.selectedItems.values.flatMap(\.messages)
        } label: {
            Label(
                MailResourcesStrings.Localizable.buttonMore,
                asset: MailResourcesAsset.plusActions.swiftUIImage
            )
        }
        .accessibilityLabel(MailResourcesStrings.Localizable.buttonMore)
        .accessibilityAddTraits(.isButton)
        .actionsPanel(
            messages: $multipleSelectedMessages,
            originFolder: viewModel.frozenFolder,
            panelSource: .threadList,
            isMultipleSelection: true,
            popoverArrowEdge: .bottom
        ) { action in
            guard action.shouldDisableMultipleSelection else { return }
            multipleSelectionViewModel.disable()
        }
    }

    private func performToolbarAction(_ action: Action) {
        let allMessages = multipleSelectionViewModel.selectedItems.values.flatMap(\.messages)
        multipleSelectionViewModel.disable()
        let originFolder = viewModel.frozenFolder
        Task {
            @InjectService var matomo: MatomoUtils
            matomo.trackBulkEvent(
                eventWithCategory: .threadActions,
                name: action.matomoName,
                numberOfItems: allMessages.count
            )

            try await actionsManager.performAction(
                target: allMessages,
                action: action,
                origin: .multipleSelection(
                    originFolder: originFolder,
                    nearestDestructiveAlert: $mainViewState.destructiveAlert,
                    nearestMessagesToMoveSheet: $messagesToMove
                )
            )
        }
    }
}
