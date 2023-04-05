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

struct SearchHistorySectionView: View {
    let viewModel: SearchViewModel

    var body: some View {
        Section {
            ForEach(viewModel.searchHistory.history, id: \.self) { searchItem in
                HStack(spacing: 8) {
                    Text(searchItem)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button {
                        deleteSearchTapped(searchItem: searchItem)
                    } label: {
                        MailResourcesAsset.close.swiftUIImage
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.accentColor)
                            .frame(width: 17, height: 17)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.matomo.track(eventWithCategory: .search, name: "fromHistory")
                    Constants.globallyResignFirstResponder()
                    viewModel.searchValue = searchItem
                    Task {
                        await viewModel.fetchThreads()
                    }
                }
            }
            .padding(.horizontal, 4)
        } header: {
            Text(MailResourcesStrings.Localizable.recentSearchesTitle)
                .textStyle(.bodySmallSecondary)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(MailResourcesAsset.backgroundColor.swiftUIColor)
        .listRowInsets(.init(top: 0, leading: 12, bottom: 0, trailing: 12))
    }

    @MainActor
    private func deleteSearchTapped(searchItem: String) {
        viewModel.matomo.track(eventWithCategory: .search, name: "deleteFromHistory")
        Task {
            await tryOrDisplayError {
                viewModel.searchHistory = await viewModel.mailboxManager.delete(
                    searchHistory: viewModel.searchHistory,
                    with: searchItem
                )
            }
        }
    }
}
