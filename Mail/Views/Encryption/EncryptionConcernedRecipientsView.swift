/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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

import MailCore
import MailCoreUI
import SwiftUI

struct EncryptionConcernedRecipientsView: View {
    @Environment(\.currentUser) private var currentUser

    @EnvironmentObject private var mailboxManager: MailboxManager

    let recipients: [Recipient]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(recipients) { recipient in
                RecipientCell(recipient: recipient, contextUser: currentUser.value, contextMailboxManager: mailboxManager)
                    .padding(.horizontal, value: .medium)
                    .padding(.vertical, value: .small)

                if let lastRecipient = recipients.last, lastRecipient != recipient {
                    IKDivider()
                }
            }
        }
    }
}

#Preview {
    EncryptionConcernedRecipientsView(recipients: PreviewHelper.sampleMessage.autoEncryptDisabledRecipients)
}
