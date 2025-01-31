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

import DesignSystem
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftModalPresentation
import SwiftUI

struct UpdateVersionAlertView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @Environment(\.openURL) private var openURL

    var onLaterPressed: (() -> Void)?
    var onDismiss: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: IKPadding.large) {
            Text(MailResourcesStrings.Localizable.updateVersionTitle)
                .textStyle(.bodyMedium)
            Text(MailResourcesStrings.Localizable.updateVersionDescription)
                .textStyle(.body)

            ModalButtonsView(primaryButtonTitle: MailResourcesStrings.Localizable.buttonUpdate,
                             secondaryButtonTitle: MailResourcesStrings.Localizable.buttonLater,
                             primaryButtonAction: updateVersion,
                             secondaryButtonAction: laterButton)
        }
        .onDisappear {
            onDismiss?()
        }
    }

    private func updateVersion() {
        matomo.track(eventWithCategory: .updateVersion, name: "update")
        openURL(DeeplinkConstants.iosPreferences)
    }

    private func laterButton() {
        matomo.track(eventWithCategory: .updateVersion, name: "later")
        onLaterPressed?()
    }
}

#Preview {
    UpdateVersionAlertView()
}
