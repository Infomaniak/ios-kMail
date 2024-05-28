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
import RealmSwift
import SwiftUI

struct SearchView: View {
    @LazyInjectService private var platformDetector: PlatformDetectable

    @EnvironmentObject private var mainViewState: MainViewState
    @EnvironmentObject private var actionsManager: ActionsManager

    @State private var multipleSelectedMessages: [Message]?
    @State private var messagesToMove: [Message]?

    @StateObject private var viewModel: SearchViewModel
    @StateObject private var multipleSelectionViewModel: SearchMultipleSelectionViewModel

    private var shouldShowHorizontalScrollbar: Bool {
        platformDetector.isMac
    }

    init(mailboxManager: MailboxManager, folder: Folder) {
        _viewModel = StateObject(wrappedValue: SearchViewModel(mailboxManager: mailboxManager, folder: folder))
        _multipleSelectionViewModel = StateObject(wrappedValue: SearchMultipleSelectionViewModel())
    }

    var body: some View {
        VStack(spacing: 0) {
            if !multipleSelectionViewModel.isEnabled {
                ScrollView(.horizontal, showsIndicators: shouldShowHorizontalScrollbar) {
                    HStack(spacing: UIPadding.small) {
                        ForEach(viewModel.filters) { filter in
                            if filter == .folder {
                                SearchFilterFolderCell(
                                    selection: $viewModel.selectedSearchFolderId,
                                    folders: viewModel.frozenFolderList
                                )
                                .accessibilityHint(MailResourcesStrings.Localizable.contentDescriptionButtonFilterSearch)
                            } else {
                                SearchFilterCell(
                                    title: filter.title,
                                    isSelected: viewModel.selectedFilters.contains(filter)
                                )
                                .accessibilityHint(MailResourcesStrings.Localizable.contentDescriptionButtonFilterSearch)
                                .accessibilityAddTraits(viewModel.selectedFilters.contains(filter) ? [.isSelected] : [])
                                .onTapGesture {
                                    viewModel.searchFilter(filter)
                                }
                            }
                        }
                    }
                    .padding(value: .regular)
                    .padding(.bottom, shouldShowHorizontalScrollbar ? UIPadding.verySmall : 0)
                }
            }

            List {
                SearchHistorySectionView(viewModel: viewModel)
                SearchContactsSectionView(viewModel: viewModel)
                SearchThreadsSectionView(viewModel: viewModel, multipleSelectionViewModel: multipleSelectionViewModel)
            }
            .listStyle(.plain)
        }
        .background(MailResourcesAsset.backgroundColor.swiftUIColor)
        .navigationBarSearchListStyle()
        .navigationBarTitleDisplayMode(.inline)
        .emptyState(isEmpty: viewModel.searchState == .noResults) {
            EmptyStateView.emptySearch
        }
        .refreshable {
            await viewModel.fetchThreads()
        }
        .searchToolbar(viewModel: viewModel, multipleSelectionViewModel: multipleSelectionViewModel)
        .onDisappear {
            if viewModel.selectedThread == nil {
                viewModel.stopObserveSearch()
            }
        }
        .onAppear {
            viewModel.selectedThread = nil
        }
        .matomoView(view: ["SearchView"])
    }
}

#Preview {
    SearchView(mailboxManager: PreviewHelper.sampleMailboxManager, folder: PreviewHelper.sampleFolder)
}
