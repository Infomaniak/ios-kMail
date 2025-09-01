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
import SwiftUI

extension View {
    func searchToolbar(
        viewModel: SearchViewModel,
        multipleSelectionViewModel: MultipleSelectionViewModel
    ) -> some View {
        modifier(SearchToolbar(
            viewModel: viewModel,
            multipleSelectionViewModel: multipleSelectionViewModel
        ))
    }
}

struct SearchToolbar: ViewModifier {
    @LazyInjectService private var matomo: MatomoUtils

    @EnvironmentObject private var mainViewState: MainViewState
    @EnvironmentObject private var actionsManager: ActionsManager

    @State private var multipleSelectedMessages: [Message]?
    @State private var messagesToMove: [Message]?

    @ObservedObject var viewModel: SearchViewModel
    @ObservedObject var multipleSelectionViewModel: MultipleSelectionViewModel

    private var selectAllButtonTitle: String {
        if multipleSelectionViewModel.selectedItems.count == viewModel.frozenThreads.count {
            return MailResourcesStrings.Localizable.buttonUnselectAll

        } else {
            return MailResourcesStrings.Localizable.buttonSelectAll
        }
    }

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
                ToolbarItem(placement: .navigationBarLeading) {
                    if multipleSelectionViewModel.isEnabled {
                        Button(MailResourcesStrings.Localizable.buttonCancel) {
                            matomo.track(eventWithCategory: .searchMultiSelection, name: "cancel")
                            multipleSelectionViewModel.disable()
                        }
                    } else {
                        CloseButton {
                            Constants.globallyResignFirstResponder()
                            mainViewState.isShowingSearch = false
                            Task {
                                await viewModel.mailboxManager.clearSearchResults()
                            }
                        }
                        .accessibilityLabel(MailResourcesStrings.Localizable.contentDescriptionButtonBack)
                    }
                }

                ToolbarItem(placement: .principal) {
                    if !multipleSelectionViewModel.isEnabled {
                        SearchTextField(value: $viewModel.searchValue) {
                            viewModel.matomo.track(eventWithCategory: .search, name: "validateSearch")
                            viewModel.addCurrentSearchTermToHistoryIfNeeded()
                            viewModel.searchThreadsForCurrentValue()
                        } onDelete: {
                            viewModel.matomo.track(eventWithCategory: .search, name: "deleteSearch")
                            viewModel.clearSearch()
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if multipleSelectionViewModel.isEnabled {
                        Button(selectAllButtonTitle) {
                            withAnimation(.default.speed(2)) {
                                multipleSelectionViewModel.selectAll(threads: viewModel.frozenThreads)
                            }
                        }
                        .animation(nil, value: multipleSelectionViewModel.selectedItems)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    if isShowingBottomBarItems {
                        Button {
                            multipleSelectedMessages = multipleSelectionViewModel.selectedItems.values.flatMap(\.messages)
                        } label: {
                            Label(MailResourcesStrings.Localizable.buttonMore, asset: MailResourcesAsset.plusActions.swiftUIImage)
                        }
                    }
                }
            }
            .toolbarSpacer(placement: .bottomBar, isVisible: isShowingBottomBarItems)
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    if isShowingBottomBarItems {
                        ForEach(multipleSelectionViewModel.toolbarActions) { action in
                            Button {
                                let allMessages = multipleSelectionViewModel.selectedItems.values.flatMap(\.messages)
                                multipleSelectionViewModel.disable()
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
                                            originFolder: viewModel.frozenSearchFolder,
                                            nearestMessagesToMoveSheet: $messagesToMove
                                        )
                                    )

                                    viewModel.refreshSearchIfNeeded(action: action)
                                }
                            } label: {
                                Label(action.shortTitle ?? action.title, asset: action.icon)
                            }
                        }
                    }
                }
            }
            .bottomBarVisibility(visibility: isBottomBarVisible ? .visible : .hidden)
            .actionsPanel(
                messages: $multipleSelectedMessages,
                originFolder: viewModel.frozenSearchFolder,
                panelSource: .threadList,
                popoverArrowEdge: .leading
            ) { action in
                viewModel.refreshSearchIfNeeded(action: action)
                multipleSelectionViewModel.disable()
            }
            .navigationTitle(
                multipleSelectionViewModel.isEnabled
                    ? MailResourcesStrings.Localizable.multipleSelectionCount(multipleSelectionViewModel.selectedItems.count)
                    : ""
            )
            .navigationBarTitleDisplayMode(.inline)
    }
}
