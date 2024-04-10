/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

struct SettingsDataManagement: View {
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                accentColor.dataPrivacyImage.swiftUIImage
                    .padding(.bottom, value: .regular)

                Text(MailResourcesStrings.Localizable.settingsDataManagementDescription)
                    .textStyle(.body)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom, value: .medium)

                ForEach(DataManagement.allCases, id: \.self) { item in
                    SettingsSubMenuCell(title: item.title, icon: item.image) {
                        // TODO:
                    }

                    if item != DataManagement.allCases.last {
                        IKDivider()
                    }
                }
            }
            .padding(.horizontal, UIPadding.regular)
        }
        .background(MailResourcesAsset.backgroundColor.swiftUIColor)
        .navigationBarTitle(MailResourcesStrings.Localizable.settingsDataManagementTitle, displayMode: .inline)
//        .matomoView(view: [MatomoUtils.View.settingsView.displayName, "SwipeActions"])
        .backButtonDisplayMode(.minimal)
    }
}

#Preview {
    SettingsDataManagement()
}
