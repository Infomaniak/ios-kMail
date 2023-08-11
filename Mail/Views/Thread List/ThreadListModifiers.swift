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
import MailResources
import SwiftUI

extension View {
    func threadListCellAppearance() -> some View {
        modifier(ThreadListCellAppearance())
    }

    func threadListToolbar(
        flushAlert: Binding<FlushAlertState?>,
        viewModel: ThreadListViewModel,
        multipleSelectionViewModel: ThreadListMultipleSelectionViewModel,
        selectAll: @escaping () -> Void
    ) -> some View {
        modifier(ThreadListToolbar(
            flushAlert: flushAlert,
            viewModel: viewModel,
            multipleSelectionViewModel: multipleSelectionViewModel,
            selectAll: selectAll
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

    @EnvironmentObject private var splitViewManager: SplitViewManager
    @EnvironmentObject private var navigationDrawerState: NavigationDrawerState
    @EnvironmentObject private var navigationState: NavigationState
    @EnvironmentObject private var actionsManager: ActionsManager

    @State private var presentedCurrentAccount: Account?
    @State private var multipleSelectedMessages: [Message]?

    @Binding var flushAlert: FlushAlertState?

    @ObservedObject var viewModel: ThreadListViewModel
    @ObservedObject var multipleSelectionViewModel: ThreadListMultipleSelectionViewModel

    let selectAll: () -> Void

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    if multipleSelectionViewModel.isEnabled {
                        Button(MailResourcesStrings.Localizable.buttonCancel) {
                            matomo.track(eventWithCategory: .multiSelection, name: "cancel")
                            multipleSelectionViewModel.isEnabled = false
                        }
                    } else {
                        if isCompactWindow {
                            Button {
                                matomo.track(eventWithCategory: .menuDrawer, name: "openByButton")
                                navigationDrawerState.open()
                            } label: {
                                MailResourcesAsset.burger.swiftUIImage
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: UIConstants.navbarIconSize, height: UIConstants.navbarIconSize)
                            }
                            .accessibilityLabel(MailResourcesStrings.Localizable.contentDescriptionButtonMenu)
                        }

                        Text(splitViewManager.selectedFolder?.localizedName ?? "")
                            .textStyle(.header1)
                    }
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if multipleSelectionViewModel.isEnabled {
                        Button(multipleSelectionViewModel.selectedItems.count == viewModel.filteredThreads.count
                            ? MailResourcesStrings.Localizable.buttonUnselectAll
                            : MailResourcesStrings.Localizable.buttonSelectAll) {
                                selectAll()
                            }
                            .animation(nil, value: multipleSelectionViewModel.selectedItems)
                    } else {
                        Button {
                            splitViewManager.showSearch = true
                        } label: {
                            MailResourcesAsset.search.swiftUIImage
                                .resizable()
                                .scaledToFit()
                                .frame(width: UIConstants.navbarIconSize, height: UIConstants.navbarIconSize)
                        }

                        Button {
                            presentedCurrentAccount = viewModel.mailboxManager.account
                        } label: {
                            if let currentAccountUser = viewModel.mailboxManager.account.user {
                                AvatarView(displayablePerson: CommonContact(user: currentAccountUser))
                            }
                        }
                        .accessibilityLabel(MailResourcesStrings.Localizable.contentDescriptionUserAvatar)
                        .sheet(item: $presentedCurrentAccount) { account in
                            AccountView(account: account)
                        }
                    }
                }
            }
            .bottomBar(isVisible: multipleSelectionViewModel.isEnabled) {
                HStack(spacing: 0) {
                    ForEach(multipleSelectionViewModel.toolbarActions) { action in
                        ToolbarButton(
                            text: action.shortTitle ?? action.title,
                            icon: action.floatingPanelIcon
                        ) {
                            let selectedMessages = multipleSelectionViewModel.selectedItems.flatMap(\.messages)
                            Task {
                                await tryOrDisplayError {
                                   try await actionsManager.performAction(
                                        target: selectedMessages,
                                        action: action,
                                        origin: .toolbar
                                    )
                                }
                            }
                            withAnimation {
                                multipleSelectionViewModel.isEnabled = false
                            }
                        }
                        .disabled(action == .archive && splitViewManager.selectedFolder?.role == .archive)
                    }

                    ToolbarButton(
                        text: MailResourcesStrings.Localizable.buttonMore,
                        icon: MailResourcesAsset.plusActions.swiftUIImage
                    ) {
                        multipleSelectedMessages = multipleSelectionViewModel.selectedItems.flatMap(\.messages)
                    }
                }
                .disabled(multipleSelectionViewModel.selectedItems.isEmpty)
            }
            .actionsPanel(messages: $multipleSelectedMessages) {
                multipleSelectionViewModel.isEnabled = false
            }
            .navigationTitle(
                multipleSelectionViewModel.isEnabled
                    ? MailResourcesStrings.Localizable.multipleSelectionCount(multipleSelectionViewModel.selectedItems.count)
                    : ""
            )
            .navigationBarTitleDisplayMode(.inline)
    }
}
