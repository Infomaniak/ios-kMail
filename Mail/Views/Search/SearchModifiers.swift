/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import InfomaniakCoreUI
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
                            viewModel.addToHistoryIfNeeded()
                            viewModel.searchThreadsForCurrentValue()
                        } onDelete: {
                            viewModel.matomo.track(eventWithCategory: .search, name: "deleteSearch")
                            viewModel.clearSearch()
                        }
                        .frame(maxWidth: .infinity)
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

                                refreshSearchIfNeeded(action: action)
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
                originFolder: viewModel.frozenSearchFolder,
                panelSource: .threadList
            ) { action in
                refreshSearchIfNeeded(action: action)
                multipleSelectionViewModel.disable()
            }
            .navigationTitle(
                multipleSelectionViewModel.isEnabled
                    ? MailResourcesStrings.Localizable.multipleSelectionCount(multipleSelectionViewModel.selectedItems.count)
                    : ""
            )
            .navigationBarTitleDisplayMode(.inline)
    }

    private func refreshSearchIfNeeded(action: Action) {
        guard action.refreshSearchResult else { return }
        Task {
            // Need to wait 500 milliseconds before reloading
            try await Task.sleep(nanoseconds: 500_000_000)
            await viewModel.fetchThreads()
        }
    }
}
