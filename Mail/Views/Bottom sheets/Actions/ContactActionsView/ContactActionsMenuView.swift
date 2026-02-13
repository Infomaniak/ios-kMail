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

struct ContactActionsMenuView<Content: View>: View {
    @Environment(\.currentUser) private var currentUser
    @EnvironmentObject private var mailboxManager: MailboxManager

    let recipient: Recipient
    let bimi: Bimi?
    @ViewBuilder let label: () -> Content

    private var actions: [Action] {
        let contact = mailboxManager.contactManager.getContact(for: recipient)

        if contact?.isRemote == true {
            return [.writeEmailAction, .copyEmailAction]
        } else {
            return [.writeEmailAction, .addContactsAction, .copyEmailAction]
        }
    }

    var body: some View {
        Menu {
            Section {
                RecipientHeaderCell(recipient: recipient)
            }
            Section {
                ForEach(actions) { action in
                    ContactActionView(recipient: recipient, action: action)
                }
            }
        } label: {
            label()
        }
    }
}

#Preview {
    ContactActionsMenuView(recipient: PreviewHelper.sampleRecipient1, bimi: nil) {
        Text(PreviewHelper.sampleUser.displayName)
    }
    .environmentObject(PreviewHelper.sampleMailboxManager)
    .environment(\.currentUser, MandatoryEnvironmentContainer(value: PreviewHelper.sampleUser))
}
