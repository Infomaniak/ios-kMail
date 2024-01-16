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

import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct SettingsNotificationsInstructionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: UIPadding.medium) {
            Text(MailResourcesStrings.Localizable.alertNotificationsDisabledTitle)
                .textStyle(.bodyMedium)
            Text(LocalizedStringKey(MailResourcesStrings.Localizable.alertNotificationsDisabledDescription))
                .textStyle(.bodySecondary)
            ModalButtonsView(
                primaryButtonTitle: MailResourcesStrings.Localizable.alertNotificationsDisabledButton,
                primaryButtonAction: openSettings
            )
        }
    }

    private func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        openURL(settingsUrl)
    }
}

#Preview {
    SettingsNotificationsInstructionsView()
}
