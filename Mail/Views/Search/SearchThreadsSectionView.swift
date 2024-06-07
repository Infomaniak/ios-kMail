/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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

import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct SearchThreadsSectionView: View {
    @EnvironmentObject private var mainViewState: MainViewState
    @EnvironmentObject private var splitViewManager: SplitViewManager

    @AppStorage(UserDefaults.shared.key(.threadDensity)) private var threadDensity = DefaultPreferences.threadDensity
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    let viewModel: SearchViewModel
    @ObservedObject var multipleSelectionViewModel: ThreadListMultipleSelectionViewModel

    var body: some View {
        if viewModel.searchState == .results {
            Section {
                ForEach(viewModel.frozenThreads) { thread in
                    SearchListCell(
                        viewModel: viewModel,
                        multipleSelectionViewModel: multipleSelectionViewModel,
                        thread: thread,
                        threadDensity: threadDensity,
                        accentColor: accentColor,
                        isSelected: mainViewState.selectedThread?.uid == thread.uid,
                        isMultiSelected: multipleSelectionViewModel.selectedItems.contains(thread)
                    )
                    .onAppear {
                        viewModel.loadNextPageIfNeeded(currentItem: thread)
                    }
                }
            } header: {
                if !viewModel.frozenThreads.isEmpty {
                    Text(MailResourcesStrings.Localizable.searchAllMessages)
                        .textStyle(.bodySmallSecondary)
                        .padding(.horizontal, value: .regular)
                }
            } footer: {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .id(UUID())
                        .threadListCellAppearance()
                }
            }
            .threadListCellAppearance()
        }
    }
}
