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

import MailCore
import MailResources
import SwiftUI

struct SearchThreadsSectionView: View {
    @EnvironmentObject private var mainViewState: MainViewState
    @EnvironmentObject private var splitViewManager: SplitViewManager

    @AppStorage(UserDefaults.shared.key(.threadDensity)) private var threadDensity = DefaultPreferences.threadDensity
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    let viewModel: SearchViewModel

    var body: some View {
        Section {
            ForEach(viewModel.frozenThreads) { thread in
                ThreadCell(thread: thread, density: threadDensity, accentColor: accentColor, origin: .search)
                    .onTapGesture {
                        didTapCell(thread: thread)
                    }
                    .background(SelectionBackground(
                        selectionType: viewModel.selectedThread == thread ? .single : .none,
                        paddingLeading: 4,
                        withAnimation: false,
                        accentColor: accentColor
                    ))
                    .onAppear {
                        viewModel.loadNextPageIfNeeded(currentItem: thread)
                    }
            }
        } header: {
            if threadDensity != .compact && !viewModel.frozenThreads.isEmpty {
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

    private func didTapCell(thread: Thread) {
        viewModel.addToHistoryIfNeeded()
        if thread.shouldPresentAsDraft {
            DraftUtils.editDraft(
                from: thread,
                mailboxManager: viewModel.mailboxManager,
                composeMessageIntent: $mainViewState.composeMessageIntent
            )
        } else {
            splitViewManager.adaptToProminentThreadView()

            // Update both viewModel and navigationState on the truth.
            viewModel.selectedThread = thread
            mainViewState.threadPath = [thread]
        }
    }
}
