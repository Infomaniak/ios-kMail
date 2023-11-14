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
import RealmSwift
import SwiftUI

struct SearchHistorySectionView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    @ObservedResults(SearchHistory.self) private var searchHistories
    private var searchHistory: SearchHistory? {
        return searchHistories.first
    }

    let viewModel: SearchViewModel

    var body: some View {
        Section {
            if let history = searchHistory?.history {
                if history.isEmpty {
                    SearchNoHistoryView()
                }

                ForEach(history, id: \.self) { searchItem in
                    HStack(spacing: UIPadding.regular) {
                        IKIcon(size: .large, image: MailResourcesAsset.clock)

                        Text(searchItem)
                            .textStyle(.bodyMedium)

                        Spacer()

                        Button {
                            deleteSearchTapped(searchItem: searchItem)
                        } label: {
                            IKIcon(
                                size: .medium,
                                image: MailResourcesAsset.close,
                                shapeStyle: MailResourcesAsset.textSecondaryColor.swiftUIColor
                            )
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
                    .padding(value: .regular)
                }
            }
        } header: {
            if searchHistory?.history.isEmpty == false {
                Text(MailResourcesStrings.Localizable.recentSearchesTitle)
                    .textStyle(.bodySmallSecondary)
                    .padding(.horizontal, value: .regular)
            }
        }
        .listRowSeparator(.hidden)
        .listRowBackground(MailResourcesAsset.backgroundColor.swiftUIColor)
        .listRowInsets(.init())
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
