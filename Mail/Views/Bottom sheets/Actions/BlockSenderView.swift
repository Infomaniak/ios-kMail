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

import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftModalPresentation
import SwiftUI

struct BlockSenderView: View {
    @LazyInjectService private var matomo: MatomoUtils
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var mailboxManager: MailboxManager
    @State private var selectedRecipient: Recipient?

    let reportedMessages: [Message]
    let action: Action = .block
    let origin: ActionOrigin

    var recipients: [Recipient] {
        Array(
            Set(
                reportedMessages
                    .flatMap(\.from)
                    .filter { recipient in
                        !recipient.isMe(currentMailboxEmail: mailboxManager.mailbox.email)
                    }
            )
        )
    }

    private func getMessages(for recipient: Recipient) -> [Message] {
        return reportedMessages.filter { message in
            message.from.contains(where: { $0 == recipient })
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(MailResourcesStrings.Localizable.blockAnExpeditorTitle)
                .textStyle(.bodyMedium)
                .padding(.bottom, value: .small)
            ForEach(recipients) { recipient in
                Button {
                    selectedRecipient = recipient
                    matomo.track(eventWithCategory: .blockUserAction, name: "selectUser")
                } label: {
                    RecipientCell(recipient: recipient)
                        .padding(.horizontal, value: .medium)
                        .padding(.vertical, value: .small)
                }
                if recipient != recipients.last {
                    IKDivider()
                }
            }
        }
        .customAlert(item: $selectedRecipient) { recipient in
            let messages = getMessages(for: recipient)
            ConfirmationBlockRecipientView(
                recipient: recipient,
                reportedMessages: messages,
                origin: origin,
                onDismiss: { dismiss() }
            )
        }
    }
}


#Preview {
    BlockSenderView(reportedMessages: PreviewHelper.sampleMessages, origin: .floatingPanel(source: .threadList))
        .accentColor(AccentColor.pink.primary.swiftUIColor)
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
