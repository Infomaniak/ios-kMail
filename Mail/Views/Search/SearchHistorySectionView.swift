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

import InfomaniakCoreUI
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftUI

struct SearchHistorySectionView: View {
    @ObservedResults(SearchHistory.self) private var searchHistories
    private var searchHistory: SearchHistory? {
        return searchHistories.first
    }

    let viewModel: SearchViewModel

    var body: some View {
        if viewModel.searchState == .history {
            Section {
                if searchHistory == nil || searchHistory?.history.isEmpty == true {
                    SearchNoHistoryView()
                }

                if let history = searchHistory?.history {
                    ForEach(history, id: \.self) { searchItem in
                        HStack(spacing: IKPadding.medium) {
                            MailResourcesAsset.clock
                                .iconSize(.large)
                                .foregroundStyle(.tint)

                            Text(searchItem)
                                .textStyle(.bodyMedium)

                            Spacer()

                            Button {
                                deleteSearchTapped(searchItem: searchItem)
                            } label: {
                                MailResourcesAsset.close
                                    .iconSize(.medium)
                                    .foregroundStyle(MailResourcesAsset.textSecondaryColor)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .accessibilityLabel(MailResourcesStrings.Localizable.contentDescriptionButtonDeleteHistory)
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
                        .padding(value: .medium)
                    }
                }
            } header: {
                if viewModel.searchState == .history && searchHistory?.history.isEmpty == false {
                    Text(MailResourcesStrings.Localizable.recentSearchesTitle)
                        .textStyle(.bodySmallSecondary)
                        .padding(.horizontal, value: .medium)
                }
            }
            .listRowSeparator(.hidden)
            .listRowBackground(MailResourcesAsset.backgroundColor.swiftUIColor)
            .listRowInsets(.init())
        }
    }

    @MainActor
    private func deleteSearchTapped(searchItem: String) {
        viewModel.matomo.track(eventWithCategory: .search, name: "deleteFromHistory")
        if let history = searchHistory?.history.thaw(),
           let searchItemIndex = history.firstIndex(where: { $0 == searchItem }) {
            try? history.realm?.write {
                history.remove(at: searchItemIndex)
            }
        }
    }
}
