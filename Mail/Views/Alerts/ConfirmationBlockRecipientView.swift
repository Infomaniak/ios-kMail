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
import Foundation
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct ConfirmationBlockRecipientView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @Environment(\.currentUser) private var currentUser

    @EnvironmentObject private var mailboxManager: MailboxManager
    @EnvironmentObject private var actionsManager: ActionsManager

    let recipient: Recipient
    let reportedMessage: Message
    let origin: ActionOrigin
    var onDismiss: (() -> Void)?

    private var contact: CommonContact {
        return CommonContactCache.getOrCreateContact(contactConfiguration: .correspondent(
            correspondent: recipient,
            contextUser: currentUser.value,
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
                Task {
                    matomo.track(eventWithCategory: .blockUserAction, name: "confirmSelectedUser")
                    try await actionsManager.performAction(
                        target: [reportedMessage],
                        action: .block,
                        origin: origin
                    )
                    onDismiss?()
                }
            }
        }
    }
}

#Preview {
    ConfirmationBlockRecipientView(
        recipient: PreviewHelper.sampleRecipient1,
        reportedMessage: PreviewHelper.sampleMessage,
        origin: .floatingPanel(source: .threadList)
    )
}
