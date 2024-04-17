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

import InfomaniakCoreUI
import MailCore
import MailResources
import SwiftUI

struct SettingsDataManagementView: View {
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                accentColor.dataPrivacyImage.swiftUIImage
                    .padding(.bottom, value: .medium)
                    .frame(maxWidth: .infinity)

                Text(MailResourcesStrings.Localizable.settingsDataManagementDescription)
                    .textStyle(.body)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom, value: .regular)
                    .padding(.horizontal, value: .regular)

                Button(MailResourcesStrings.Localizable.settingsDataManagementSourceCode) {
                    openURL(URLConstants.sourceCode.url)
                }
                .buttonStyle(.ikLink(isInlined: true))
                .padding(UIPadding.regular)

                ForEach(DataManagement.allCases, id: \.self) { item in
                    SettingsSubMenuCell(title: item.title, icon: item.image) {
                        switch item {
                        case .matomo:
                            SettingsDataManagementDetailView.matomo
                        case .sentry:
                            SettingsDataManagementDetailView.sentry
                        }
                    }

                    if item != DataManagement.allCases.last {
                        IKDivider()
                    }
                }
            }
        }
        .background(MailResourcesAsset.backgroundColor.swiftUIColor)
        .navigationBarTitle(MailResourcesStrings.Localizable.settingsDataManagementTitle, displayMode: .inline)
        .backButtonDisplayMode(.minimal)
        .matomoView(view: [MatomoUtils.View.settingsView.displayName, "dataPrivacy"])
    }
}

#Preview {
    SettingsDataManagementView()
}
