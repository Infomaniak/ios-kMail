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

import InfomaniakCoreUI
import MailCore
import MailResources
import RealmSwift
import SwiftUI

struct SearchView: View {
    @Environment(\.isCompactWindow) private var isCompactWindow

    @EnvironmentObject private var splitViewManager: SplitViewManager

    @StateObject private var viewModel: SearchViewModel

    init(mailboxManager: MailboxManager, folder: Folder) {
        _viewModel = StateObject(wrappedValue: SearchViewModel(mailboxManager: mailboxManager, folder: folder))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: UIPadding.small) {
                    ForEach(viewModel.filters) { filter in
                        if filter == .folder {
                            SearchFilterFolderCell(selection: $viewModel.selectedSearchFolderId, folders: viewModel.folderList)
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
            }

            List {
                if viewModel.searchState == .history {
                    SearchHistorySectionView(viewModel: viewModel)
                } else if viewModel.searchState == .results {
                    SearchContactsSectionView(viewModel: viewModel)
                    SearchThreadsSectionView(viewModel: viewModel)
                }
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
        .onDisappear {
            if viewModel.selectedThread == nil {
                viewModel.observationSearchThreadToken?.invalidate()
            }
        }
        .onAppear {
            viewModel.selectedThread = nil
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                CloseButton {
                    Constants.globallyResignFirstResponder()
                    splitViewManager.showSearch = false
                }
                .accessibilityLabel(MailResourcesStrings.Localizable.contentDescriptionButtonBack)
            }

            ToolbarItem(placement: .principal) {
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
        .matomoView(view: ["SearchView"])
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(mailboxManager: PreviewHelper.sampleMailboxManager, folder: PreviewHelper.sampleFolder)
    }
}
