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

    @State private var multipleSelectedMessages: [Message]?

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

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    if #available(iOS 16.0, *), isShowingBottomBarItems {
                        moreButton
                    }
                }
            }
            .toolbarSpacer(placement: .bottomBar, isVisible: isShowingBottomBarItems)
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    if isShowingBottomBarItems {
                        ForEach(multipleSelectionViewModel.toolbarActions) { action in
                            Button {
                                performToolbarAction(action)
                            } label: {
                                Label(action.shortTitle ?? action.title, asset: action.icon)
                            }
                            .accessibilityLabel(action.title)
                            .accessibilityAddTraits(.isButton)

                            LegacyToolbarSpacer()
                        }

                        if #unavailable(iOS 16.0), isShowingBottomBarItems {
                            moreButton
                        }
                    }
                }
            }
            .bottomBarVisibility(visibility: isBottomBarVisible ? .visible : .hidden)
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
                name: action.matomoName.capitalized,
                numberOfItems: allMessages.count
            )

            try await actionsManager.performAction(
                target: allMessages,
                action: action,
                origin: .multipleSelection(
                    originFolder: originFolder,
                    nearestDestructiveAlert: $mainViewState.destructiveAlert,
                    nearestMessagesToMoveSheet: nil
                )
            )
        }
    }
}
