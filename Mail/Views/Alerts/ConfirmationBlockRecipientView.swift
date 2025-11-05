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
    @Environment(\.currentUser) private var currentUser

    @EnvironmentObject private var mailboxManager: MailboxManager
    @EnvironmentObject private var actionsManager: ActionsManager

    let recipients: [Recipient]
    let reportedMessages: [Message]
    let origin: ActionOrigin
    var onDismiss: (() -> Void)?

    private var contacts: [CommonContact] {
        return recipients.map {
            CommonContactCache.getOrCreateContact(contactConfiguration: .correspondent(
                correspondent: $0,
                contextUser: currentUser.value,
                contextMailboxManager: mailboxManager
            ))
        }
    }

    private var confirmationBlockTexts: (title: String, description: String) {
        guard contacts.count == 1, let contact = contacts.first else {
            return (
                MailResourcesStrings.Localizable.blockMultipleExpeditorsTitle(contacts.count),
                MailResourcesStrings.Localizable.confirmationToBlockMultipleExpeditorsText
            )
        }

        return (
            MailResourcesStrings.Localizable.blockExpeditorTitle(contact.fullName),
            MailResourcesStrings.Localizable.confirmationToBlockAnExpeditorText(contact.email)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(confirmationBlockTexts.title)
                .textStyle(.bodyMedium)
                .padding(.bottom, IKPadding.alertTitleBottom)

            Text(confirmationBlockTexts.description)
                .textStyle(.body)
                .padding(.bottom, IKPadding.alertDescriptionBottom)

            ModalButtonsView(primaryButtonTitle: MailResourcesStrings.Localizable.buttonBlockAnExpeditor) {
                Task {
                    @InjectService var matomo: MatomoUtils
                    matomo.track(eventWithCategory: .blockUserAction, name: "confirmSelectedUser")
                    try await actionsManager.performAction(
                        target: reportedMessages,
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
        recipients: [PreviewHelper.sampleRecipient1],
        reportedMessages: [PreviewHelper.sampleMessage],
        origin: .floatingPanel(source: .threadList)
    )
    .environment(\.currentUser, MandatoryEnvironmentContainer(value: PreviewHelper.sampleUser))
}
