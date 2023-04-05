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

struct SearchContactsSectionView: View {
    @AppStorage(UserDefaults.shared.key(.threadDensity)) private var threadDensity = DefaultPreferences.threadDensity

    let viewModel: SearchViewModel

    var body: some View {
        Section {
            ForEach(viewModel.contacts) { contact in
                RecipientAutocompletionCell(recipient: contact)
                    .onTapGesture {
                        viewModel.matomo.track(eventWithCategory: .search, name: "selectContact")
                        Constants.globallyResignFirstResponder()
                        viewModel.searchThreadsForContact(contact)
                    }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, threadDensity.cellVerticalPadding)
        } header: {
            if !viewModel.contacts.isEmpty {
                Text(MailResourcesStrings.Localizable.contactsSearch)
                    .textStyle(.bodySmallSecondary)
            }
        }
        .listRowInsets(.init(top: 0, leading: 12, bottom: 0, trailing: 12))
        .listRowSeparator(.hidden)
        .listRowBackground(MailResourcesAsset.backgroundColor.swiftUIColor)
    }
}
