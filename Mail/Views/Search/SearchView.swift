/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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

import InfomaniakCore
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var mainViewState: MainViewState

    @StateObject private var viewModel: SearchViewModel
    @StateObject private var multipleSelectionViewModel: MultipleSelectionViewModel

    init(mailboxManager: MailboxManager, folder: Folder) {
        _viewModel = StateObject(wrappedValue: SearchViewModel(mailboxManager: mailboxManager, folder: folder))
        _multipleSelectionViewModel = StateObject(wrappedValue: MultipleSelectionViewModel())
    }

    var body: some View {
        Group {
            VStack(spacing: 0) {
                Rectangle() // Needed to fix navBar clear color bug
                    .frame(height: 0.2)
                    .foregroundStyle(.clear)
                if !multipleSelectionViewModel.isEnabled {
                    SearchFilterHeaderView(viewModel: viewModel)
                }
                SearchViewList(viewModel: viewModel, multipleSelectionViewModel: multipleSelectionViewModel)
            }
        }
        .accessibilityAction(.escape) {
            mainViewState.isShowingSearch = false
        }
        .accessibilityAction(.escape) {
            mainViewState.isShowingSearch = false
        }
        .background(MailResourcesAsset.backgroundColor.swiftUIColor)
        .navigationBarSearchListStyle()
        .emptyState(isEmpty: viewModel.searchState == .noResults) {
            EmptyStateView.emptySearch
        }
        .refreshable {
            multipleSelectionViewModel.disable()
            await viewModel.fetchThreads()
        }
        .toolbarAppStyle()
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
