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
    @EnvironmentObject var splitViewManager: SplitViewManager

    @StateObject var viewModel: SearchViewModel

    @Binding private var editedMessageDraft: Draft?

    let isCompact: Bool

    init(mailboxManager: MailboxManager,
         folder: Folder,
         editedMessageDraft: Binding<Draft?>,
         isCompact: Bool) {
        _editedMessageDraft = editedMessageDraft
        _viewModel = StateObject(wrappedValue: SearchViewModel(mailboxManager: mailboxManager, folder: folder))
        self.isCompact = isCompact
    }

    var body: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(viewModel.filters) { filter in
                        if filter == .folder {
                            SearchFilterFolderCell(selection: $viewModel.selectedSearchFolderId, folders: viewModel.folderList)
                                .accessibilityHint(MailResourcesStrings.Localizable.contentDescriptionButtonFilterSearch)
                                .padding(.horizontal, 12)
                        } else {
                            SearchFilterCell(
                                title: filter.title,
                                isSelected: viewModel.selectedFilters.contains(filter)
                            )
                            .accessibilityHint(MailResourcesStrings.Localizable.contentDescriptionButtonFilterSearch)
                            .accessibilityAddTraits(viewModel.selectedFilters.contains(filter) ? [.isSelected] : [])
                            .padding(.vertical, 2)
                            .padding(.trailing, 0)
                            .padding(.leading, 12)
                            .onTapGesture {
                                viewModel.searchFilter(filter)
                            }
                        }
                    }
                }
            }
            .padding(.top, 16)

            List {
                if viewModel.searchState == .noHistory {
                    SearchNoHistoryView()
                } else if viewModel.searchState == .history {
                    SearchHistorySectionView(viewModel: viewModel)
                } else if viewModel.searchState == .results {
                    SearchContactsSectionView(viewModel: viewModel)
                    SearchThreadsSectionView(viewModel: viewModel, editedMessageDraft: $editedMessageDraft)
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
                Button {
                    Constants.globallyResignFirstResponder()
                    splitViewManager.showSearch = false
                } label: {
                    Image(isCompact ? MailResourcesAsset.arrowLeft.name : MailResourcesAsset.closeBig.name)
                }
                .accessibilityLabel(MailResourcesStrings.Localizable.contentDescriptionButtonBack)
            }

            ToolbarItem(placement: .principal) {
                SearchTextField(value: $viewModel.searchValue) {
                    viewModel.matomo.track(eventWithCategory: .search, name: "validateSearch")
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
        SearchView(mailboxManager: PreviewHelper.sampleMailboxManager,
                   folder: PreviewHelper.sampleFolder,
                   editedMessageDraft: .constant(nil),
                   isCompact: true)
    }
}
