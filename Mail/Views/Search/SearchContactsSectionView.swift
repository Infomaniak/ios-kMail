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

struct SearchContactsSectionView: View {
    @AppStorage(UserDefaults.shared.key(.threadDensity)) private var threadDensity = DefaultPreferences.threadDensity

    let viewModel: SearchViewModel

    var body: some View {
        if viewModel.searchState == .results {
            Section {
                ForEach(viewModel.frozenContacts) { contact in
                    RecipientCell(recipient: contact)
                        .onTapGesture {
                            viewModel.matomo.track(eventWithCategory: .search, name: "selectContact")
                            viewModel.addToSearchHistoryIfNeeded()
                            Constants.globallyResignFirstResponder()
                            viewModel.searchThreadsForContact(contact)
                        }
                }
                .padding(.vertical, threadDensity.cellVerticalPadding)
                .padding(.leading, UIPadding.small + UIConstants.unreadIconSize + UIPadding.small)
                .padding(.trailing, value: .regular)
            } header: {
                if !viewModel.frozenContacts.isEmpty {
                    Text(MailResourcesStrings.Localizable.contactsSearch)
                        .textStyle(.bodySmallSecondary)
                        .padding(.horizontal, value: .regular)
                }
            }
            .listRowInsets(.init())
            .listRowSeparator(.hidden)
            .listRowBackground(MailResourcesAsset.backgroundColor.swiftUIColor)
        }
    }
}
