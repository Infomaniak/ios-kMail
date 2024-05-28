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

import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

extension View {
    func threadListCellAppearance() -> some View {
        modifier(ThreadListCellAppearance())
    }

    func threadListToolbar(
        flushAlert: Binding<FlushAlertState?>,
        viewModel: ThreadListViewModel,
        multipleSelectionViewModel: ThreadListMultipleSelectionViewModel
    ) -> some View {
        modifier(ThreadListToolbar(
            flushAlert: flushAlert,
            viewModel: viewModel,
            multipleSelectionViewModel: multipleSelectionViewModel
        ))
    }
}

struct ThreadListCellAppearance: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowSeparator(.hidden)
            .listRowInsets(.init())
            .listRowBackground(MailResourcesAsset.backgroundColor.swiftUIColor)
    }
}

struct ThreadListToolbar: ViewModifier {
    @LazyInjectService private var matomo: MatomoUtils

    @Environment(\.isCompactWindow) private var isCompactWindow

    @EnvironmentObject private var actionsManager: ActionsManager

    @State private var multipleSelectedMessages: [Message]?
    @State private var messagesToMove: [Message]?

    @Binding var flushAlert: FlushAlertState?

    @ObservedObject var viewModel: ThreadListViewModel
    @ObservedObject var multipleSelectionViewModel: ThreadListMultipleSelectionViewModel

    private var selectAllButtonTitle: String {
        if multipleSelectionViewModel.selectedItems.count == viewModel.filteredThreads.count {
            return MailResourcesStrings.Localizable.buttonUnselectAll

        } else {
            return MailResourcesStrings.Localizable.buttonSelectAll
        }
    }

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        if multipleSelectionViewModel.isEnabled {
                            Button(MailResourcesStrings.Localizable.buttonCancel) {
                                matomo.track(eventWithCategory: .multiSelection, name: "cancel")
                                multipleSelectionViewModel.disable()
                            }
                        } else {
                            if isCompactWindow {
                                MenuDrawerButton()
                            }

                            let textMaxWidth = isCompactWindow ? UIScreen.main.bounds.size.width - geometry.safeAreaInsets
                                .leading - geometry.safeAreaInsets.trailing - UIConstants.navbarIconsSpace : 215
                            Text(viewModel.frozenFolder.localizedName)
                                .textStyle(.header1)
                                .frame(maxWidth: textMaxWidth, alignment: .leading)
                        }
                    }

                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        if multipleSelectionViewModel.isEnabled {
                            Button(selectAllButtonTitle) {
                                withAnimation(.default.speed(2)) {
                                    multipleSelectionViewModel.selectAll(threads: viewModel.filteredThreads)
                                }
                            }
                            .animation(nil, value: multipleSelectionViewModel.selectedItems)
                        } else {
                            SearchButton()

                            AccountButton()
                        }
                    }
                }
                .bottomBar(isVisible: multipleSelectionViewModel.isEnabled) {
                    HStack(spacing: 0) {
                        ForEach(multipleSelectionViewModel.toolbarActions) { action in
                            ToolbarButton(
                                text: action.shortTitle ?? action.title,
                                icon: action.icon
                            ) {
                                let allMessages = multipleSelectionViewModel.selectedItems.flatMap(\.messages)
                                multipleSelectionViewModel.disable()
                                let originFolder = viewModel.frozenFolder
                                Task {
                                    matomo.trackBulkEvent(
                                        eventWithCategory: .threadActions,
                                        name: action.matomoName.capitalized,
                                        numberOfItems: multipleSelectionViewModel.selectedItems.count
                                    )

                                    try await actionsManager.performAction(
                                        target: allMessages,
                                        action: action,
                                        origin: .multipleSelection(
                                            originFolder: originFolder,
                                            nearestFlushAlert: $flushAlert,
                                            nearestMessagesToMoveSheet: $messagesToMove
                                        )
                                    )
                                }
                            }
                        }

                        ToolbarButton(
                            text: MailResourcesStrings.Localizable.buttonMore,
                            icon: MailResourcesAsset.plusActions.swiftUIImage
                        ) {
                            multipleSelectedMessages = multipleSelectionViewModel.selectedItems.flatMap(\.messages)
                        }
                    }
                }
                .actionsPanel(
                    messages: $multipleSelectedMessages,
                    originFolder: viewModel.frozenFolder,
                    panelSource: .threadList, completionHandler: { _ in
                        multipleSelectionViewModel.disable()
                    }
                )
                .sheet(item: $messagesToMove) { messages in
                    MoveEmailView(
                        mailboxManager: viewModel.mailboxManager,
                        movedMessages: messages,
                        originFolder: viewModel.frozenFolder
                    )
                    .sheetViewStyle()
                }
                .navigationTitle(
                    multipleSelectionViewModel.isEnabled
                        ? MailResourcesStrings.Localizable.multipleSelectionCount(multipleSelectionViewModel.selectedItems.count)
                        : ""
                )
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
