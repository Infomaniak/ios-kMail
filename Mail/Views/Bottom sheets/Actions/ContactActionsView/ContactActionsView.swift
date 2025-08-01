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
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import SwiftUI

struct ContactActionsView: View {
    @Environment(\.currentUser) private var currentUser
    @EnvironmentObject private var mailboxManager: MailboxManager

    let recipient: Recipient
    let bimi: Bimi?

    private var actions: [Action] {
        let contact = mailboxManager.contactManager.getContact(for: recipient)

        if contact?.isRemote == true {
            return [.writeEmailAction, .copyEmailAction]
        } else {
            return [.writeEmailAction, .addContactsAction, .copyEmailAction]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IKPadding.mini) {
            let contactConfiguration = ContactConfiguration.correspondent(
                correspondent: recipient,
                associatedBimi: bimi,
                contextUser: currentUser.value,
                contextMailboxManager: mailboxManager
            )
            let contact = CommonContactCache.getOrCreateContact(contactConfiguration: contactConfiguration)
            ContactActionsHeaderView(displayablePerson: contact, bimi: bimi)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(actions) { action in
                    if action != actions.first {
                        IKDivider()
                    }

                    ContactActionView(recipient: recipient, action: action)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .matomoView(view: [MatomoUtils.View.bottomSheet.displayName, "ContactActionsView"])
    }
}

#Preview {
    ContactActionsView(recipient: PreviewHelper.sampleRecipient1, bimi: nil)
        .environmentObject(PreviewHelper.sampleMailboxManager)
        .environment(\.currentUser, MandatoryEnvironmentContainer(value: PreviewHelper.sampleUser))
}
