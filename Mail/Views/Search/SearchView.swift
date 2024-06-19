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
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var mainViewState: MainViewState
    @EnvironmentObject private var actionsManager: ActionsManager

    @State private var multipleSelectedMessages: [Message]?
    @State private var messagesToMove: [Message]?

    @StateObject private var viewModel: SearchViewModel
    @StateObject private var multipleSelectionViewModel: MultipleSelectionViewModel

    init(mailboxManager: MailboxManager, folder: Folder) {
        _viewModel = StateObject(wrappedValue: SearchViewModel(mailboxManager: mailboxManager, folder: folder))
        _multipleSelectionViewModel = StateObject(wrappedValue: MultipleSelectionViewModel())
    }

    var body: some View {
        Group {
            if !multipleSelectionViewModel.isEnabled {
                VStack(spacing: 0) {
                    SearchFilterHeaderView(viewModel: viewModel)

                    SearchViewList(viewModel: viewModel, multipleSelectionViewModel: multipleSelectionViewModel)
                }
            } else {
                SearchViewList(viewModel: viewModel, multipleSelectionViewModel: multipleSelectionViewModel)
            }
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
