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
import RealmSwift
import SwiftUI

struct SearchView: View {
    @InjectService var platformDetector: PlatformDetectable

    @EnvironmentObject private var mainViewState: MainViewState

    @StateObject private var viewModel: SearchViewModel

    private var showHorizontalScrollbar: Bool {
        platformDetector.isMac
    }

    private var bottomPadding: CGFloat {
        platformDetector.isMac ? UIPadding.verySmall : 0
    }

    init(mailboxManager: MailboxManager, folder: Folder) {
        _viewModel = StateObject(wrappedValue: SearchViewModel(mailboxManager: mailboxManager, folder: folder))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: showHorizontalScrollbar) {
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
                .padding(.bottom, bottomPadding)
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
                    mainViewState.isShowingSearch = false
                    Task {
                        await viewModel.mailboxManager.clearSearchResults()
                    }
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

#Preview {
    SearchView(mailboxManager: PreviewHelper.sampleMailboxManager, folder: PreviewHelper.sampleFolder)
}
