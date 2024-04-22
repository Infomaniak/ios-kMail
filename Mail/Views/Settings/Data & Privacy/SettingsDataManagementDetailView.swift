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

struct SettingsDataManagementDetailView: View {
    let image: Image
    let title: String
    let description: String

    let userDefaults: ReferenceWritableKeyPath<UserDefaults, Bool>
    let matomoName: String

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                image
                    .padding(.vertical, value: .regular)

                Text(description)
                    .textStyle(.body)
                    .multilineTextAlignment(.leading)
                    .padding(UIPadding.regular)

                IKDivider()

                SettingsToggleCell(
                    title: MailResourcesStrings.Localizable.settingsAuthorizeTracking,
                    userDefaults: userDefaults,
                    matomoCategory: .settingsDataPrivacy,
                    matomoName: matomoName
                )
            }
        }
        .navigationBarTitle(title, displayMode: .inline)
    }
}

extension SettingsDataManagementDetailView {
    static let matomo = SettingsDataManagementDetailView(
        image: MailResourcesAsset.matomoText.swiftUIImage,
        title: MailResourcesStrings.Localizable.settingsMatomoTitle,
        description: MailResourcesStrings.Localizable.settingsMatomoDescription,
        userDefaults: \.isMatomoAuthorized,
        matomoName: "matomo"
    )

    static let sentry = SettingsDataManagementDetailView(
        image: MailResourcesAsset.sentryText.swiftUIImage,
        title: MailResourcesStrings.Localizable.settingsSentryTitle,
        description: MailResourcesStrings.Localizable.settingsSentryDescription,
        userDefaults: \.isSentryAuthorized,
        matomoName: "sentry"
    )
}

#Preview {
    SettingsDataManagementDetailView.matomo
}
