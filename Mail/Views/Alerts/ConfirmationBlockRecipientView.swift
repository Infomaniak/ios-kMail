//
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

import Foundation
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct ConfirmationBlockRecipientView: View {
    @LazyInjectService private var matomo: MatomoUtils
    @EnvironmentObject private var mailboxManager: MailboxManager
    let recipient: Recipient
    var contact: CommonContact {
        return CommonContactCache.getOrCreateContact(contactConfiguration: .correspondent(
            correspondent: recipient,
            associatedBimi: nil,
            contextMailboxManager: mailboxManager
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(MailResourcesStrings.Localizable.blockExpeditorTitle(contact.fullName))
                .textStyle(.bodyMedium)
                .padding(.bottom, IKPadding.alertTitleBottom)

            Text(MailResourcesStrings.Localizable.confirmationToBlockAnExpeditorText(recipient.email))
                .textStyle(.body)
                .padding(.bottom, IKPadding.alertDescriptionBottom)

            ModalButtonsView(primaryButtonTitle: MailResourcesStrings.Localizable.buttonBlockAnExpeditor) {
                matomo.track(eventWithCategory: .newMessage, name: "sendWithoutSubjectConfirm")
            }
        }
    }
}

#Preview {
    ConfirmationBlockRecipientView(recipient: PreviewHelper.sampleRecipient1)
}
