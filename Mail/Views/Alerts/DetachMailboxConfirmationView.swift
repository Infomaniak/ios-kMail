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

import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct DetachMailboxConfirmationView: View {
    @LazyInjectService private var matomo: MatomoUtils
    @LazyInjectService private var accountManager: AccountManager

    @EnvironmentObject private var navigationState: RootViewState

    let mailbox: Mailbox

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(MailResourcesStrings.Localizable.popupDetachMailboxTitle)
                .textStyle(.bodyMedium)
                .padding(.bottom, UIPadding.alertTitleBottom)
            Text(attributedString())
                .textStyle(.bodySecondary)
                .padding(.bottom, UIPadding.alertDescriptionBottom)
            ModalButtonsView(primaryButtonTitle: MailResourcesStrings.Localizable.buttonConfirm, primaryButtonAction: detach)
        }
    }

    func attributedString() -> AttributedString {
        do {
            var text = try AttributedString(markdown: MailResourcesStrings.Localizable
                .popupDetachMailboxDescription("**\(mailbox.email)**"))

            if let range = text.range(of: mailbox.email) {
                text[range].foregroundColor = MailResourcesAsset.textPrimaryColor.swiftUIColor
            }

            return text
        } catch {
            return ""
        }
    }

    private func detach() async {
        matomo.track(eventWithCategory: .invalidPasswordMailbox, name: "detachMailboxConfirm")
        await tryOrDisplayError {
            try await accountManager.detachMailbox(mailbox: mailbox)
            navigationState.transitionToRootViewDestination(.mainView)
        }
    }
}

#Preview {
    DetachMailboxConfirmationView(mailbox: PreviewHelper.sampleMailbox)
}
