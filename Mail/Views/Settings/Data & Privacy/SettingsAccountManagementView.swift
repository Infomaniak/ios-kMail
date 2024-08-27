/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import InfomaniakCore
import InfomaniakCoreUI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct SettingsAccountManagementView: View {
    let account: Account

    var body: some View {
        ScrollView {
            VStack(spacing: IKPadding.medium) {
                VStack(alignment: .leading, spacing: IKPadding.extraSmall) {
                    Text(MailResourcesStrings.Localizable.usernameTitle)
                        .textStyle(.header2)
                    Text(account.user.displayName)
                        .textStyle(.bodySecondary)
                }
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: IKPadding.extraSmall) {
                    Text(MailResourcesStrings.Localizable.attachMailboxInputHint)
                        .textStyle(.header2)
                    Text(account.user.email)
                        .textStyle(.bodySecondary)
                }
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

                IKDivider(type: .menu)
            }
        }
        .background(MailResourcesAsset.backgroundColor.swiftUIColor)
        .navigationBarTitle(MailResourcesStrings.Localizable.settingsAccountManagementTitle, displayMode: .inline)
        .padding(.horizontal, value: .medium)
    }
}

#Preview {
    SettingsAccountManagementView(account: PreviewHelper.sampleAccount)
}
