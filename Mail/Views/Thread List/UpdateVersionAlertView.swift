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
import InfomaniakBugTracker
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftModalPresentation
import SwiftUI

struct UpdateVersionAlertView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @Environment(\.openURL) var openURL
    @EnvironmentObject private var mailboxManager: MailboxManager

    @AppStorage(UserDefaults.shared.key(.updateOSViewDismissed)) private var updateOSViewDismissed = DefaultPreferences
        .updateOSViewDismissed

    @ModalState private var isShowingBugTracker = false

    var isShownFromFeedbackOrHelpButton: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: UIPadding.medium) {
            Text("Votre expérience peut être dégradée car votre appareil n’est pas à jour")
                .textStyle(.bodyMedium)
            Text("Pour votre sécurité et améliorer votre expérience, veuillez mettre à jour votre appareil.")
                .textStyle(.body)

            ModalButtonsView(primaryButtonTitle: MailResourcesStrings.Localizable.buttonUpdate,
                             secondaryButtonTitle: MailResourcesStrings.Localizable.buttonLater,
                             primaryButtonAction: updateVersion,
                             secondaryButtonAction: dismissUpdateVersionView)
        }
    }

    private func updateVersion() {
        matomo.track(eventWithCategory: .syncAutoConfig, name: "openSettings")
        let url: URL
        url = DeeplinkConstants.iosPreferences
        openURL(url)
        dismissUpdateVersionView()
    }

    private func dismissUpdateVersionView() {
        if isShownFromFeedbackOrHelpButton {
            sendFeedback()
        }
        updateOSViewDismissed = true
    }

    private func sendFeedback() {
        if mailboxManager.account.user?.isStaff == false {
            isShowingBugTracker.toggle()
        } else if let userReportURL = URL(string: MailResourcesStrings.Localizable.urlUserReportiOS) {
            openURL(userReportURL)
        }
    }
}

#Preview {
    UpdateVersionAlertView(isShownFromFeedbackOrHelpButton: true)
}
